  $ $TESTDIR/../../..//../../_build/default/stanc.exe --auto-format "$TESTDIR/../../..//function-signatures/math/functions/log10.stan"
  data {
    int d_int;
    real d_real;
  }
  transformed data {
    int transformed_data_int;
    real transformed_data_real;
    transformed_data_real <- log10(d_int);
    transformed_data_real <- log10(d_real);
  }
  parameters {
    real p_real;
    real y_p;
  }
  transformed parameters {
    real transformed_param_real;
    transformed_param_real <- log10(d_int);
    transformed_param_real <- log10(d_real);
    transformed_param_real <- log10(p_real);
  }
  model {
    y_p ~ normal(0, 1);
  }
  

