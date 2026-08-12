# Up-front input validation and identifiability guards. These lock in the error
# messages users rely on and guard against regressions in the guard logic.

test_that("too few significant tests is rejected with a helpful message", {
  expect_error(
    zcurve(zval = c(2.1, 2.3, 2.5), show_plot = FALSE),
    "Insufficient data"
  )
})

test_that("min_int lowers the minimum so small sets can be fit", {
  z <- seq(2.1, 4.2, length.out = 15)          # 15 significant z-values
  expect_error(zcurve(zval = z, show_plot = FALSE), "Insufficient data")   # default 20
  expect_s3_class(
    zcurve(zval = z, min_int = 10, boot_iter = 0, show_plot = FALSE),
    "zcurve"
  )
})

test_that("z_sd must match ncp in length", {
  z <- sim_sig_z(seed = 20)
  expect_error(
    zcurve(zval = z, ncp = 0:6, z_sd = rep(1, 3), show_plot = FALSE),
    "z_sd must have the same length as ncp"
  )
})

test_that("negative ncp components are rejected under selection", {
  z <- sim_sig_z(seed = 21)
  expect_error(
    zcurve(zval = z, ncp = c(-1, 0:6), z_sd = rep(1, 8), show_plot = FALSE),
    "not identified under selection"
  )
})

test_that("negative ncp is allowed without selection (int_beg <= min(ncp))", {
  # Genomics-style setting: full distribution observed, window opened to components.
  set.seed(22)
  z <- rnorm(400, 1, 1)                          # includes negative and null z
  expect_s3_class(
    zcurve(zval = z, ncp = c(-2:6), z_sd = rep(1, 9),
           int_beg = -2, folded = FALSE, directional = TRUE,
           boot_iter = 0, show_plot = FALSE),
    "zcurve"
  )
})

test_that("boot_iter validation and double-supply are caught", {
  z <- sim_sig_z(seed = 23)
  expect_error(zcurve(zval = z, boot_iter = -5, show_plot = FALSE),
               "boot_iter must be one nonnegative integer")
  expect_error(
    zcurve(zval = z, boot_iter = 10,
           control = zcurve_control(boot_iter = 10), show_plot = FALSE),
    "not both"
  )
})

test_that("min_effect and plot_control inputs are validated", {
  z <- sim_sig_z(seed = 24)
  expect_error(zcurve(zval = z, min_effect = -1, show_plot = FALSE),
               "min_effect must be one nonnegative")
  expect_error(zcurve(zval = z, plot_control = c(ylim = 1), show_plot = FALSE),
               "plot_control must be a list")
  expect_error(
    zcurve(zval = z, plot_control = list(not_an_option = 1), show_plot = FALSE),
    "unknown plot_control option"
  )
})

test_that("z-value and p-value inputs give the same power estimates", {
  z    <- sim_sig_z(seed = 25)
  pval <- 2 * stats::pnorm(-abs(z))              # two-sided p from |z|
  fz   <- zcurve(zval = z,    boot_iter = 0, show_plot = FALSE)
  fp   <- zcurve(pval = pval, boot_iter = 0, show_plot = FALSE)
  expect_equal(fz$EDR[1], fp$EDR[1], tolerance = 1e-6)
  expect_equal(fz$ERR[1], fp$ERR[1], tolerance = 1e-6)
})
