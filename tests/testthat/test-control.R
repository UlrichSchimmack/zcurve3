# zcurve_control(): defaults, and that its options actually reach the fit.

test_that("zcurve_control() exposes the documented options with defaults", {
  ctl <- zcurve_control()
  expect_type(ctl, "list")
  expect_true(all(c("boot_iter", "seed", "parallel", "floor_correct",
                    "floor_reps", "es_null_share") %in% names(ctl)))
  expect_true(ctl$floor_correct)
  expect_equal(ctl$floor_reps, 5)
  expect_equal(ctl$es_null_share, 0.5)
})

test_that("boot_iter supplied through control drives the bootstrap", {
  z   <- sim_sig_z(seed = 30)
  fit <- zcurve(zval = z,
                control = zcurve_control(boot_iter = 40, seed = 1, parallel = FALSE),
                show_plot = FALSE)
  expect_equal(fit$metadata$bootstrap_iterations, 40)
  expect_named(fit$EDR, c("EDR_pe", "EDR_lb", "EDR_ub"))
})

test_that("floor correction does not increase estimated heterogeneity", {
  # The floor correction only subtracts an SE-driven inflation floor, so the
  # corrected heterogeneity is never above the uncorrected one.
  d  <- sim_sig_es(seed = 31)
  on  <- zcurve(yi = d$yi, sei = d$sei, boot_iter = 0, show_plot = FALSE,
                control = zcurve_control(floor_correct = TRUE))
  off <- zcurve(yi = d$yi, sei = d$sei, boot_iter = 0, show_plot = FALSE,
                control = zcurve_control(floor_correct = FALSE))
  expect_lte(on$effect_size$heterogeneity_significant[1],
             off$effect_size$heterogeneity_significant[1] + 1e-8)
})
