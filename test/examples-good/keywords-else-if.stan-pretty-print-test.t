  $ $TESTDIR//../../_build/default/stanc.exe --auto-format "$TESTDIR//keywords-else-if.stan"
  parameters {
    real a;
    real if2;
  }
  model {
    if (1 > 2) {
      a ~ normal(0, 1);
    }
    else if2 ~ normal(0, 1);
  }
  

