  $ $TESTDIR/..//../../_build/default/stanc.exe --auto-format "$TESTDIR/..//stat_comp_benchmarks_models/low_dim_corr_gauss.stan"
  transformed data {
    vector[2] mu;
    real sigma1;
    real sigma2;
    real rho;
    matrix[2, 2] Sigma;
    mu[1] = 0.0;
    mu[2] = 3.0;
    rho = 0.5;
    sigma1 = 1.0;
    sigma2 = 2.0;
    Sigma[1, 1] = sigma1 * sigma1;
    Sigma[1, 2] = rho * sigma1 * sigma2;
    Sigma[2, 1] = rho * sigma1 * sigma2;
    Sigma[2, 2] = sigma2 * sigma2;
  }
  parameters {
    vector[2] z;
  }
  model {
    z ~ multi_normal(mu, Sigma);
  }
  generated quantities {
    real delta_var1;
    real delta_var2;
    real delta_corr;
    delta_var1 = square(z[1] - mu[1]) - sigma1 * sigma1;
    delta_var2 = square(z[2] - mu[2]) - sigma2 * sigma2;
    delta_corr = (z[1] - mu[1]) * (z[2] - mu[2]) / (sigma1 * sigma2) - rho;
  }
  

