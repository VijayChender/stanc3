open Core_kernel
open Middle

let pos = "pos__"
let is_scalar = function SInt | SReal -> true | _ -> false

let data_read smeta (decl_id, st) =
  let decl_var =
    { expr= Var decl_id
    ; emeta= {mloc= smeta; mtype= remove_size st; madlevel= DataOnly} }
  in
  let swrap stmt = {stmt; smeta} in
  let bodyfn var =
    let pos_var = {expr= Var pos; emeta= internal_meta} in
    let readfnapp var =
      let f =
        internal_funapp FnReadData
          [{var with expr= Lit (Str, decl_id)}]
          var.emeta
      in
      {expr= Indexed (f, [Single pos_var]); emeta= {var.emeta with mtype= UInt}}
    in
    let pos_increment =
      if is_scalar st then []
      else
        [Assignment ((pos, UInt, []), binop pos_var Plus (mir_int 1)) |> swrap]
    in
    SList
      ( assign_indexed (remove_size st) decl_id smeta readfnapp var
      :: pos_increment )
    |> swrap
  in
  let pos_reset = Assignment ((pos, UInt, []), loop_bottom) |> swrap in
  [pos_reset; for_scalar_inv st bodyfn decl_var smeta]

let rec base_type = function
  | SArray (t, _) -> base_type t
  | SVector _ | SRowVector _ | SMatrix _ -> UReal
  | x -> remove_size x

let rec base_ut_to_string = function
  | UMatrix -> "matrix"
  | UVector -> "vector"
  | URowVector -> "row_vector"
  | UReal -> "scalar"
  | UInt -> "integer"
  | UArray t -> base_ut_to_string t
  | t ->
      raise_s
        [%message "Another place where it's weird to get " (t : unsizedtype)]

let param_read smeta (decl_id, (ucst, cst)) =
  let decl_id, decl =
    match cst = ucst with
    | true -> (decl_id, [])
    | false ->
      let decl_id = decl_id ^ "_in__" in
      let d =
        Decl {decl_adtype= AutoDiffable; decl_id; decl_type= Sized ucst}
      in
      (decl_id, [{stmt= d; smeta}])
  in
  let unconstrained_decl_var =
    { expr= Var decl_id
    ; emeta= {mloc= smeta; mtype= remove_size cst; madlevel= AutoDiffable} }
  in
  let bodyfn var =
    let readfnapp var =
      internal_funapp FnReadParam
        ( { expr= Lit (Str, base_ut_to_string (remove_size ucst))
          ; emeta= internal_meta }
          :: eigen_size ucst )
        {var.emeta with mtype= base_type ucst}
    in
    assign_indexed (remove_size cst) decl_id smeta readfnapp var
  in
  decl @ [for_eigen ucst bodyfn unconstrained_decl_var smeta]

let escape_name str =
  str
  |> String.substr_replace_all ~pattern:"." ~with_:"_"
  |> String.substr_replace_all ~pattern:"-" ~with_:"_"

let rec add_jacobians {stmt; smeta} =
  match stmt with
  | Assignment (lhs, {expr= FunApp (CompilerInternal, f, args); emeta})
    when internal_fn_of_string f = Some FnConstrain ->
      let var n = {expr= Var n; emeta= internal_meta} in
      let assign rhs = {stmt= Assignment (lhs, rhs); smeta} in
      { stmt=
          IfElse
            ( var "jacobian__"
            , assign
                {expr= FunApp (CompilerInternal, f, args @ [var "lp__"]); emeta}
            , Some (assign {expr= FunApp (CompilerInternal, f, args); emeta})
            )
      ; smeta }
  | _ -> {stmt= map_statement Fn.id add_jacobians stmt; smeta}

(* Make sure that all if-while-and-for bodies are safely wrapped in a block in such a way that we can insert a location update before.
   The blocks make sure that the program with the inserted location update is still well-formed C++ though.
   *)
let rec ensure_body_in_block {stmt; smeta} =
  let in_block {stmt; smeta} =
    { stmt=
        ( match stmt with
        | Block l | SList l -> Block l
        | stmt -> Block [{stmt; smeta}] )
    ; smeta }
  in
  let ensure_body_in_block_base stmt =
    match stmt with
    | IfElse (_, _, _) | While (_, _) | For _ ->
        map_statement (fun x -> x) in_block stmt
    | _ -> stmt
  in
  { stmt=
      ensure_body_in_block_base
        (map_statement (fun x -> x) ensure_body_in_block stmt)
  ; smeta }

let flatten_slist = function {stmt= SList ls; _} -> ls | x -> [x]

let add_reads stmts vars mkread =
  let var_names = String.Map.of_alist_exn vars in
  let add_read_to_decl = function
    | {stmt= Decl {decl_id; _}; smeta} as s when Map.mem var_names decl_id ->
        s :: mkread smeta (decl_id, Map.find_exn var_names decl_id)
    | s -> [s]
  in
  List.concat_map ~f:add_read_to_decl stmts |> List.concat_map ~f:flatten_slist

let gen_write (decl_id, sizedtype) =
  let bodyfn var =
    { stmt=
        NRFunApp (CompilerInternal, string_of_internal_fn FnWriteParam, [var])
    ; smeta= no_span }
  in
  for_scalar_inv sizedtype bodyfn
    { expr= Var decl_id
    ; emeta= {internal_meta with mtype= remove_size sizedtype} }
    no_span

let rec contains_var_expr is_vident accum {expr; _} =
  accum
  ||
  match expr with
  | Var v when is_vident v -> true
  | _ -> fold_expr (contains_var_expr is_vident) false expr

(* When a parameter's unconstrained type and its constrained type are different,
   we generate a new variable "<param_name>_in__" and read into that. We now need
   to change the FnConstrain calls to constrain that variable and assign to the
   actual <param_name> var.
*)
let constrain_in_params params_with_both_types stmts =
  let is_target_var (name, (unconstrained_st, constrained_st)) =
    if (unconstrained_st = constrained_st) then None else Some name
  in
  let target_vars = params_with_both_types |> List.filter_map ~f:is_target_var |> String.Set.of_list in
  let rec change_constrain_target s =
    match s.stmt with
    | Assignment (_, {expr= FunApp (CompilerInternal, f, args); _})
      when ( internal_fn_of_string f = Some FnConstrain
           || internal_fn_of_string f = Some FnUnconstrain )
           && List.exists args
                ~f:(contains_var_expr (Set.mem target_vars) false) ->
        let rec change_var_expr e =
          match e.expr with
          | Var vident when Set.mem target_vars vident ->
              {e with expr= Var (vident ^ "_in__")}
          | _ -> {e with expr= map_expr change_var_expr e.expr}
        in
        let rec change_var_stmt s =
          {s with stmt= map_statement change_var_expr change_var_stmt s.stmt}
        in
        change_var_stmt s
    | _ -> {s with stmt= map_statement Fn.id change_constrain_target s.stmt}
  in
  List.map ~f:change_constrain_target stmts

let rec insert_before f to_insert = function
  | [] -> to_insert
  | hd :: tl ->
      if f hd then to_insert @ (hd :: tl)
      else hd :: insert_before f to_insert tl

let%expect_test "insert before" =
  let l = [1; 2; 3; 4; 5; 6] |> insert_before (( = ) 6) [999] in
  [%sexp (l : int list)] |> print_s ;
  [%expect {| (1 2 3 4 5 999 6) |}]

let trans_prog (p : typed_prog) =
  let init_pos =
    [ Decl {decl_adtype= DataOnly; decl_id= pos; decl_type= Sized SInt}
    ; Assignment ((pos, UInt, []), loop_bottom) ]
    |> List.map ~f:(fun stmt -> {stmt; smeta= no_span})
  in
  let log_prob = List.map ~f:add_jacobians p.log_prob in
  let param_writes = List.map ~f:gen_write p.constrained_parameters in
  let tparam_writes = List.map ~f:gen_write p.transformed_parameters  in
  let gq_writes = List.map ~f:gen_write p.generated_quantities in
  let tparam_start {stmt; _} =
    match stmt with
    | IfElse (cond, _, _)
      when contains_var_expr (( = ) "emit_transformed_parameters__") false cond
      ->
        true
    | _ -> false
  in
  let gq_start {stmt; _} =
    match stmt with
    | IfElse
        ( { expr= FunApp (_, _, [{expr= Var "emit_generated_quantities__"; _}]); _
          }
        , _
        , _ ) ->
        true
    | _ -> false
  in
  let params_with_both_types =
    List.zip_exn p.unconstrained_parameters p.constrained_parameters
  |> List.map ~f:(fun ((name, ucst), (_, cst)) -> name, (ucst, cst))
  in
  let with_param_reads block =
    add_reads block params_with_both_types param_read
    |> constrain_in_params params_with_both_types
  in
  let gq =
    ( with_param_reads p.generate_quantities
    |> insert_before tparam_start param_writes
    |> insert_before gq_start tparam_writes )
    @ gq_writes
  in
  let p =
    { p with
      log_prob= with_param_reads log_prob
    ; prog_name= escape_name p.prog_name
    ; prepare_data= init_pos @ add_reads p.prepare_data p.input_vars data_read
    ; transform_inits=
        init_pos
        @ add_reads p.transform_inits p.constrained_parameters data_read
        @ List.map ~f:gen_write p.constrained_parameters
    ; generate_quantities= gq }
  in
  map_prog Fn.id ensure_body_in_block p
