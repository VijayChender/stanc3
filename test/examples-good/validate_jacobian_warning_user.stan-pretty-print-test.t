  $ $TESTDIR//../../_build/default/stanc.exe --auto-format "$TESTDIR//validate_jacobian_warning_user.stan"
  parameters {
    vector[1] y;
  }
  model {
    exp(y[1]) ~ normal(0, 2);
  }
  

