# Forest plot: the bootstrap requirement, the returned data frame, file
# auto-sizing, and label handling (label_id and the mismatch warning).
# render_null() lives in helper-sim.R.

test_that("forest plot requires a bootstrapped fit", {
  d   <- sim_sig_es(n_total = 60, seed = 1)
  fit <- zcurve(yi = d$yi, sei = d$sei, boot_iter = 0, show_plot = FALSE)
  expect_error(render_null(zcurve_forest(fit)), "requires a bootstrapped fit")
})

test_that("forest returns one row per test with power_adjusted", {
  d   <- sim_sig_es(n_total = 60, seed = 2)
  fit <- zcurve(yi = d$yi, sei = d$sei, boot_iter = 40,
                control = test_control(), show_plot = FALSE)
  # Disable the display filters so every significant test appears as a row.
  res <- render_null(
    zcurve_forest(fit, es_lb_min = -100, z_min = 0, k_max = 10000)
  )

  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), length(d$yi))
  expect_true(all(c("study_id", "cluster_id", "power_adjusted") %in% names(res)))
  expect_true(all(res$power_adjusted >= 0 & res$power_adjusted <= 1))
})

test_that("forest auto-sizes to a file", {
  skip_if_not(capabilities("png"), "png device not available")
  d   <- sim_sig_es(n_total = 60, seed = 3)
  fit <- zcurve(yi = d$yi, sei = d$sei, boot_iter = 40,
                control = test_control(), show_plot = FALSE)
  f   <- tempfile(fileext = ".png")
  on.exit(unlink(f))
  suppressMessages(zcurve_forest(fit, file = f))
  expect_true(file.exists(f))
  expect_gt(file.info(f)$size, 0)
})

test_that("label_id maps labels onto study ids without error", {
  d   <- sim_sig_es(n_total = 60, seed = 4)
  ids <- paste0("s", seq_along(d$yi))
  fit <- zcurve(yi = d$yi, sei = d$sei, study_id = ids, boot_iter = 40,
                control = test_control(), show_plot = FALSE)
  titles <- paste("Study", seq_along(d$yi))
  expect_no_error(
    render_null(zcurve_forest(fit, labels = titles, label_id = ids))
  )
})

test_that("named labels that match no study id warn and fall back", {
  d   <- sim_sig_es(n_total = 60, seed = 5)
  fit <- zcurve(yi = d$yi, sei = d$sei, boot_iter = 40,
                control = test_control(), show_plot = FALSE)
  bad <- stats::setNames("Mislabelled", "not_a_real_id")
  expect_warning(render_null(zcurve_forest(fit, labels = bad)))
})
