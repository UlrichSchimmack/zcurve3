# S3 methods: print, summary, and plot should run cleanly and expose the
# documented summary structure. render_null() lives in helper-sim.R.

test_that("print.zcurve runs and returns its object invisibly", {
  fit <- zcurve(zval = sim_sig_z(seed = 40), boot_iter = 0, show_plot = FALSE)
  expect_output(print(fit))
  capture.output(vis <- withVisible(print(fit))$visible)
  expect_false(vis)
})

test_that("summary.zcurve exposes the estimate table", {
  fit <- zcurve(zval = sim_sig_z(seed = 41), boot_iter = 0, show_plot = FALSE)
  s   <- summary(fit)

  expect_s3_class(s, "summary_zcurve")
  expect_true(all(c("measure", "estimate") %in% names(s$estimates)))
  expect_true(all(c("EDR", "ERR", "FDR") %in% s$estimates$measure))
  expect_output(print(s))
})

test_that("summary prints a prediction interval when effect sizes are supplied", {
  d   <- sim_sig_es(seed = 42)
  fit <- zcurve(yi = d$yi, sei = d$sei, boot_iter = 40,
                control = test_control(), show_plot = FALSE)
  expect_output(print(summary(fit)), "Prediction interval")
})

test_that("plot.zcurve draws without error", {
  fit <- zcurve(zval = sim_sig_z(seed = 43), boot_iter = 0, show_plot = FALSE)
  expect_no_error(render_null(plot(fit)))
})
