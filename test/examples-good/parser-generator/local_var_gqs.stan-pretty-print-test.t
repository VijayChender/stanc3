  $ $TESTDIR/..//../../_build/default/stanc.exe --auto-format "$TESTDIR/..//parser-generator/local_var_gqs.stan"
  generated quantities {
    real p2;
    for (x in 1 : 10) p2 = x;
    {
      int a;
      real b[20, 30];
      matrix[40, 50] ar_mat[60, 70];
      ar_mat[1, 1, 1, 1] = 1.0;
      p2 = b[1, 1];
    }
  }
  

