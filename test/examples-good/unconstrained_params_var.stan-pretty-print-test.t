  $ $TESTDIR//../../_build/default/stanc.exe --auto-format "$TESTDIR//unconstrained_params_var.stan"
  parameters {
    real mu;
    real<lower=0> sigma;
  }
  model {
    1 ~ normal(mu, sigma);
    2 ~ normal(mu, sigma);
    3 ~ normal(mu, sigma);
  }
  

