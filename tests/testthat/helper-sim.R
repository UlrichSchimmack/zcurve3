# Shared, deterministic data generators for the test suite.
# Each generator seeds its own RNG so tests are reproducible regardless of order.

CRIT_05 <- stats::qnorm(1 - 0.05 / 2)   # two-sided z critical value at alpha = .05

# Significant |z| values from a set of studies with heterogeneous true power.
sim_sig_z <- function(n_total = 400, ncp_mean = 2.5, ncp_sd = 0.7, seed = 1,
                      crit = CRIT_05) {
  set.seed(seed)
  ncp <- abs(stats::rnorm(n_total, ncp_mean, ncp_sd))
  z   <- abs(stats::rnorm(n_total, ncp, 1))
  z[z > crit]
}

# Significant effect sizes (yi) with standard errors (sei) from a random-effects
# population: true effects ~ N(mu, tau), observed with per-study sampling error.
sim_sig_es <- function(n_total = 300, mu = 0.5, tau = 0.3, seed = 1,
                       n_min = 40, n_max = 120, crit = CRIT_05) {
  set.seed(seed)
  di  <- stats::rnorm(n_total, mu, tau)
  N   <- sample(n_min:n_max, n_total, replace = TRUE)
  sei <- sqrt(4 / N)                       # approximate SE of Cohen's d, two groups
  yi  <- stats::rnorm(n_total, di, sei)
  keep <- abs(yi / sei) > crit
  list(yi = yi[keep], sei = sei[keep], di = di[keep], n_sig = sum(keep))
}

# A reproducible control: fixed bootstrap seed, no parallelism (fast + stable).
test_control <- function(seed = 123, ...) {
  zcurve_control(seed = seed, parallel = FALSE, ...)
}

# Evaluate a plotting call against a throwaway device so nothing opens a window,
# and return its (invisible) value.
render_null <- function(expr) {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  expr
}
