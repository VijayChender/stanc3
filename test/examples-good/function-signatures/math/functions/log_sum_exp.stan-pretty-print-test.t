  $ $TESTDIR/../../..//../../_build/default/stanc.exe --auto-format "$TESTDIR/../../..//function-signatures/math/functions/log_sum_exp.stan"
  data {
    int d_int;
    int r_int;
    real d_real;
    real r_real;
  }
  transformed data {
    int transformed_data_int;
    real transformed_data_real;
    transformed_data_real <- log_sum_exp(d_real, r_real);
    transformed_data_real <- log_sum_exp(d_int, r_real);
    transformed_data_real <- log_sum_exp(d_real, d_int);
    transformed_data_real <- log_sum_exp(r_int, d_int);
  }
  parameters {
    real p_real;
    real y_p;
  }
  transformed parameters {
    real transformed_param_real;
    transformed_param_real <- log_sum_exp(d_real, r_real);
    transformed_param_real <- log_sum_exp(d_int, r_real);
    transformed_param_real <- log_sum_exp(d_real, d_int);
    transformed_param_real <- log_sum_exp(r_int, d_int);
    transformed_param_real <- log_sum_exp(r_int, p_real);
    transformed_param_real <- log_sum_exp(r_real, p_real);
    transformed_param_real <- log_sum_exp(p_real, p_real);
    transformed_param_real <- log_sum_exp(p_real, r_int);
    transformed_param_real <- log_sum_exp(p_real, r_real);
  }
  model {
    y_p ~ normal(0, 1);
  }
  

