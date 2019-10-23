open Core_kernel
open Common
open Helpers

type fun_arg_decl = (UnsizedType.autodifftype * string * UnsizedType.t) list
[@@deriving sexp, hash, map]

type 'a fun_def =
  { fdrt: UnsizedType.t option
  ; fdname: string
  ; fdargs: (UnsizedType.autodifftype * string * UnsizedType.t) list
  ; fdbody: 'a
  ; fdloc: Location_span.t sexp_opaque [@compare.ignore] }
[@@deriving compare, hash, map, sexp, map, fold]

type io_block = Parameters | TransformedParameters | GeneratedQuantities
[@@deriving sexp, hash]

(** Transformations (constraints) for global variable declarations *)
type 'e transformation =
  | Identity
  | Lower of 'e
  | Upper of 'e
  | LowerUpper of 'e * 'e
  | Offset of 'e
  | Multiplier of 'e
  | OffsetMultiplier of 'e * 'e
  | Ordered
  | PositiveOrdered
  | Simplex
  | UnitVector
  | CholeskyCorr
  | CholeskyCov
  | Correlation
  | Covariance
[@@deriving sexp, compare, map, hash, fold]

type 'e outvar =
  { out_unconstrained_st: 'e SizedType.t
  ; out_constrained_st: 'e SizedType.t
  ; out_block: io_block
  ; out_trans: 'e transformation }
[@@deriving sexp, map, hash, fold]

type ('a, 'b) t =
  { functions_block: 'b fun_def list
  ; input_vars: (string * 'a SizedType.t) list
  ; prepare_data: 'b list (* data & transformed data decls and statements *)
  ; log_prob: 'b list (*assumes data & params are in scope and ready*)
  ; generate_quantities: 'b list (* assumes data & params ready & in scope*)
  ; transform_inits: 'b list
  ; output_vars: (string * 'a outvar) list
  ; prog_name: string
  ; prog_path: string }
[@@deriving sexp, map, fold]

(* -- Pretty printers -- *)
let pp_fun_arg_decl ppf (autodifftype, name, unsizedtype) =
  Fmt.pf ppf "%a%a %s" UnsizedType.pp_autodifftype autodifftype UnsizedType.pp
    unsizedtype name

let pp_fun_def pp_s ppf = function
  | {fdrt; fdname; fdargs; fdbody; _} -> (
    match fdrt with
    | Some rt ->
        Fmt.pf ppf {|@[<v2>%a %s%a {@ %a@]@ }|} UnsizedType.pp rt fdname
          Fmt.(list pp_fun_arg_decl ~sep:comma |> parens)
          fdargs pp_s fdbody
    | None ->
        Fmt.pf ppf {|@[<v2>%s %s%a {@ %a@]@ }|} "void" fdname
          Fmt.(list pp_fun_arg_decl ~sep:comma |> parens)
          fdargs pp_s fdbody )

let pp_io_block ppf = function
  | Parameters -> Fmt.string ppf "parameters"
  | TransformedParameters -> Fmt.string ppf "transformed_parameters"
  | GeneratedQuantities -> Fmt.string ppf "generated_quantities"

let pp_block label pp_elem ppf = function
  | [] -> ()
  | elems ->
      Fmt.pf ppf {|@[<v2>%a {@ %a@]@ }|} pp_keyword label
        Fmt.(list ~sep:cut pp_elem)
        elems ;
      Format.pp_force_newline ppf ()

let pp_functions_block pp_s ppf {functions_block; _} =
  pp_block "functions" pp_s ppf functions_block

let pp_prepare_data pp_s ppf {prepare_data; _} =
  pp_block "prepare_data" pp_s ppf prepare_data

let pp_log_prob pp_s ppf {log_prob; _} = pp_block "log_prob" pp_s ppf log_prob

let pp_generate_quantities pp_s ppf {generate_quantities; _} =
  pp_block "generate_quantities" pp_s ppf generate_quantities

let pp_transform_inits pp_s ppf {transform_inits; _} =
  pp_block "transform_inits" pp_s ppf transform_inits

let pp_output_var pp_e ppf
    (name, {out_unconstrained_st; out_constrained_st; out_block; _}) =
  Fmt.pf ppf "@[<h>%a %a %s; //%a@]" pp_io_block out_block (SizedType.pp pp_e)
    out_constrained_st name (SizedType.pp pp_e) out_unconstrained_st

let pp_input_var pp_e ppf (name, sized_ty) =
  Fmt.pf ppf "@[<h>%a %s;@]" (SizedType.pp pp_e) sized_ty name

let pp_input_vars pp_e ppf {input_vars; _} =
  pp_block "input_vars" (pp_input_var pp_e) ppf input_vars

let pp_output_vars pp_e ppf {output_vars; _} =
  pp_block "output_vars" (pp_output_var pp_e) ppf output_vars

let pp pp_e pp_s ppf prog =
  Format.open_vbox 0 ;
  pp_functions_block (pp_fun_def pp_s) ppf prog ;
  Fmt.cut ppf () ;
  pp_input_vars pp_e ppf prog ;
  Fmt.cut ppf () ;
  pp_prepare_data pp_s ppf prog ;
  Fmt.cut ppf () ;
  pp_log_prob pp_s ppf prog ;
  Fmt.cut ppf () ;
  pp_generate_quantities pp_s ppf prog ;
  Fmt.cut ppf () ;
  pp_transform_inits pp_s ppf prog ;
  Fmt.cut ppf () ;
  pp_output_vars pp_e ppf prog ;
  Format.close_box ()

(* Programs with typed expressions and locations *)
module Typed = struct
  type nonrec t = (Expr.Typed.t, Stmt.Located.t) t

  let pp ppf x = pp Expr.Typed.pp Stmt.Located.pp ppf x
  let sexp_of_t = sexp_of_t Expr.Typed.sexp_of_t Stmt.Located.sexp_of_t
  let t_of_sexp = t_of_sexp Expr.Typed.t_of_sexp Stmt.Located.t_of_sexp
end

(* Programs with labelled expressions and statements *)
module Labelled = struct
  type nonrec t = (Expr.Labelled.t, Stmt.Labelled.t) t

  let pp ppf x = pp Expr.Labelled.pp Stmt.Labelled.pp ppf x
  let sexp_of_t = sexp_of_t Expr.Labelled.sexp_of_t Stmt.Labelled.sexp_of_t
  let t_of_sexp = t_of_sexp Expr.Labelled.t_of_sexp Stmt.Labelled.t_of_sexp

  (* let label ?(init = 0) (prog : Typed.t) : t =
    let incr_label =
      State.(get >>= fun label -> put (label + 1) >>= fun _ -> return label)
    in
    let f {Expr.Typed.Meta.adlevel; type_; loc} =
      incr_label
      |> State.map ~f:(fun label ->
             Expr.Labelled.Meta.create ~type_ ~loc ~adlevel ~label () )
    and g loc =
      incr_label
      |> State.map ~f:(fun label -> Stmt.Labelled.Meta.create ~loc ~label ())
    in
    Traversable_state.traverse prog
      ~f:(Traversable_expr_state.traverse ~f)
      ~g:(Traversable_stmt_state.traverse ~f ~g)
    |> State.run_state ~init |> fst *)

  let empty =
    { Stmt.Labelled.exprs= Label.Int_label.Map.empty
    ; stmts= Label.Int_label.Map.empty }

  let rec associate ?init:(assocs = empty) prog =
    let assoc_fundef =
      List.fold_left prog.functions_block ~init:assocs ~f:associate_fun_def
    in
    let assoc_input_vars =
      List.fold_left prog.input_vars ~init:assoc_fundef
        ~f:(fun assocs (_, st) ->
          {assocs with exprs= SizedType.associate ~init:assocs.exprs st} )
    in
    let assoc_prepare_data =
      List.fold_left prog.prepare_data ~init:assoc_input_vars
        ~f:(fun assocs stmt -> Stmt.Labelled.associate ~init:assocs stmt )
    in
    let assoc_log_prog =
      List.fold_left prog.log_prob ~init:assoc_prepare_data
        ~f:(fun assocs stmt -> Stmt.Labelled.associate ~init:assocs stmt )
    in
    let assoc_generate_quants =
      List.fold_left prog.generate_quantities ~init:assoc_log_prog
        ~f:(fun assocs stmt -> Stmt.Labelled.associate ~init:assocs stmt )
    in
    let assoc_transform_inits =
      List.fold_left prog.transform_inits ~init:assoc_generate_quants
        ~f:(fun assocs stmt -> Stmt.Labelled.associate ~init:assocs stmt )
    in
    List.fold_left prog.output_vars ~init:assoc_transform_inits
      ~f:associate_outvar

  and associate_fun_def assocs {fdbody; _} =
    Stmt.Labelled.associate ~init:assocs fdbody

  and associate_outvar assocs (_, {out_constrained_st; out_unconstrained_st; _})
      =
    let exprs =
      SizedType.(
        associate
          ~init:(associate ~init:assocs.exprs out_unconstrained_st)
          out_constrained_st)
    in
    {assocs with exprs}
end

module Numbered = struct
  type nonrec t = (Expr.Typed.t, Stmt.Numbered.t) t

  let pp ppf x = pp Expr.Typed.pp Stmt.Numbered.pp ppf x
  let sexp_of_t = sexp_of_t Expr.Typed.sexp_of_t Stmt.Numbered.sexp_of_t
  let t_of_sexp = t_of_sexp Expr.Typed.t_of_sexp Stmt.Numbered.t_of_sexp
end

module Helpers = struct
  open Stmt.Fixed
  open Stmt.Fixed.Pattern

  (** [iter_stmt_transform transform stmts] will run the transform function
    on the list of statements until the list of statements stops changing.

    In our use case this could be replaced with a bottom-up map.
*)
  let iter_stmt_transform f stmts =
    let old_stmts = ref stmts in
    let new_stmts = ref (f stmts) in
    (* The count here just enforces a hard limit on the number of iterations.
     In principle, we should only use this function with monotonic update
     functions, but in practice we may get that wrong from time to time and
     this count keeps us from infinite loops.
  *)
    let count = ref 0 in
    while Stdlib.( != ) !old_stmts !new_stmts && !count < 100 do
      old_stmts := !new_stmts ;
      new_stmts := f !old_stmts ;
      count := !count + 1
    done ;
    !new_stmts

  (** [cleanup_stmts statements] will do a few simple transformations like
    removing Skips, collapsing empty blocks and SLists, etc. *)
  let rec cleanup_stmts_one_pass stmts =
    let rec cleanup_stmt s =
      let ellide = {s with pattern= Skip} in
      match s.pattern with
      | Block [] | SList [] -> ellide
      | For {body= {pattern= Skip; _}; _} -> ellide
      | While (_, {pattern= Skip; _}) -> ellide
      | SList ls -> {s with pattern= SList (cleanup_stmts_one_pass ls)}
      | Block ls -> {s with pattern= Block (cleanup_stmts_one_pass ls)}
      | _ ->
          {s with pattern= Stmt.Fixed.Pattern.map Fn.id cleanup_stmt s.pattern}
    in
    let is_decl = function {pattern= Decl _; _} -> true | _ -> false in
    let flatten_block s =
      match s.pattern with
      | SList ls | Block ls ->
          if List.for_all ~f:(Fn.non is_decl) ls then ls else [s]
      | _ -> [s]
    in
    let ellide_skip s = match s.pattern with Skip -> [] | _ -> [s] in
    List.map stmts ~f:cleanup_stmt
    |> List.concat_map ~f:flatten_block
    |> List.concat_map ~f:ellide_skip

  let cleanup_empty_stmts stmts =
    iter_stmt_transform cleanup_stmts_one_pass stmts

  let%expect_test "cleanup" =
    let open Expr.Helpers in
    let swrap pattern = {pattern; meta= Location_span.empty} in
    let body = Block [Skip |> swrap] |> swrap in
    let s = For {loopvar= "i"; lower= loop_bottom; upper= loop_bottom; body} in
    let res = [s |> swrap] |> cleanup_empty_stmts in
    [%sexp (res : Stmt.Located.t list)] |> print_s ;
    [%expect {|
    () |}]

  let map_stmts f p =
    { p with
      prepare_data= f p.prepare_data
    ; log_prob= f p.log_prob
    ; generate_quantities= f p.generate_quantities
    ; transform_inits= f p.transform_inits }
end