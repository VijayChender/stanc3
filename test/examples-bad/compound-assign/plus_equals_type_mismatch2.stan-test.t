  $ $TESTDIR/..//../../_build/default/stanc.exe "$TESTDIR/..//compound-assign/plus_equals_type_mismatch2.stan"
  Semantic error at file ".*/examples-bad/compound-assign/..//compound-assign/plus_equals_type_mismatch2.stan", line 4, characters 2-9: (re)
  Ill-typed arguments supplied to assignment operator +=: lhs has type real and rhs has type vector. Available signatures:
  (vector, vector) => void
  (vector, int) => void
  (vector, real) => void
  (row_vector, row_vector) => void
  (row_vector, int) => void
  (real, int) => void
  (matrix, int) => void
  (row_vector, real) => void
  (real, real) => void
  (matrix, real) => void
  (matrix, matrix) => void
  (int, int) => void
  [1]

