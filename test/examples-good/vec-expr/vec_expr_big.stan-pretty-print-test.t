  $ $TESTDIR/..//../../_build/default/stanc.exe --auto-format "$TESTDIR/..//vec-expr/vec_expr_big.stan"
  transformed data {
    real x = 12;
    row_vector[100] a = [1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10];
    vector[100] b = [1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10]';
    matrix[1, 100] c = [[1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, x, x, x, 7, 8, 9.0, 10]];
  }
  parameters {
    real<lower=0, upper=1> theta;
  }
  transformed parameters {
    real y = 12;
    row_vector[100] d = [1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10];
    vector[100] e = [1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10]';
    matrix[1, 100] f = [[1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10, 1.0, 2.0, 3.0, y, y, y, 7, 8, 9.0, 10]];
  }
  

