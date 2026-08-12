# Core fitting behaviour on z-value input: object shape, estimate ranges,
# theoretical invariants, and reproducibility.

test_that("zcurve() returns a well-formed zcurve object", {
  z   <- sim_sig_z(seed = 1)
  fit <- zcurve(zval = z, boot_iter = 0, show_plot = FALSE)

  expect_s3_class(fit, "zcurve")
  expect_true(all(c("EDR", "ERR", "FDR", "ODR", "ncp", "w_all",
                    "local_power", "metadata") %in% names(fit)))
  expect_equal(fit$metadata$n_significant, length(z))
})

test_that("headline estimates lie in [0, 1]", {
  fit <- zcurve(zval = sim_sig_z(seed = 2), boot_iter = 0, show_plot = FALSE)
  for (m in c("ODR", "EDR", "ERR", "FDR")) {
    val <- fit[[m]][1]
    expect_true(is.finite(val), info = m)
    expect_gte(val, 0)
    expect_lte(val, 1)
  }
})

test_that("ERR >= EDR (replication rate conditions on significance)", {
  # Significant results are selected for higher power, so the expected
  # replication rate is never below the expected discovery rate.
  fit <- zcurve(zval = sim_sig_z(seed = 3), boot_iter = 0, show_plot = FALSE)
  expect_gte(fit$ERR[1], fit$EDR[1] - 1e-6)
})

test_that("EDR orders with true power (high-power > low-power)", {
  hi <- zcurve(zval = sim_sig_z(ncp_mean = 3.6, ncp_sd = 0.5, seed = 10),
               boot_iter = 0, show_plot = FALSE)
  lo <- zcurve(zval = sim_sig_z(ncp_mean = 1.4, ncp_sd = 0.5, seed = 11),
               boot_iter = 0, show_plot = FALSE)
  expect_gt(hi$EDR[1], lo$EDR[1])
})

test_that("point estimates are deterministic across runs", {
  z  <- sim_sig_z(seed = 4)
  f1 <- zcurve(zval = z, boot_iter = 0, show_plot = FALSE)
  f2 <- zcurve(zval = z, boot_iter = 0, show_plot = FALSE)
  expect_identical(f1$EDR[1], f2$EDR[1])
  expect_identical(f1$ERR[1], f2$ERR[1])
  expect_identical(f1$w_all, f2$w_all)
})

test_that("bootstrap CIs are reproducible with a fixed seed and bracket the PE", {
  z  <- sim_sig_z(seed = 5)
  b1 <- zcurve(zval = z, boot_iter = 40, control = test_control(), show_plot = FALSE)
  b2 <- zcurve(zval = z, boot_iter = 40, control = test_control(), show_plot = FALSE)
  expect_identical(b1$EDR, b2$EDR)

  expect_named(b1$EDR, c("EDR_pe", "EDR_lb", "EDR_ub"))
  expect_lte(b1$EDR["EDR_lb"], b1$EDR["EDR_pe"] + 1e-9)
  expect_gte(b1$EDR["EDR_ub"], b1$EDR["EDR_pe"] - 1e-9)
})

test_that("EM method runs and returns estimates in range", {
  fit <- zcurve(zval = sim_sig_z(seed = 6), est_method = "EM",
                boot_iter = 0, show_plot = FALSE)
  expect_s3_class(fit, "zcurve")
  expect_gte(fit$EDR[1], 0)
  expect_lte(fit$EDR[1], 1)
})
