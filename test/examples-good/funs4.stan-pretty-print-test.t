  $ $TESTDIR//../../_build/default/stanc.exe --auto-format "$TESTDIR//funs4.stan"
  functions {
    real unit_normal_log(real y) {
      return normal_log(y, 0, 1);
    }
  }
  parameters {
    real y;
  }
  model {
    increment_log_prob(unit_normal_log(y));
  }
  

