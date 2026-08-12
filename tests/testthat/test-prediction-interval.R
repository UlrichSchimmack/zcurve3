# Prediction interval for a new study: shape, folding, the bootstrap requirement,
# and the defining property that estimation error widens it beyond heterogeneity.

test_that("bootstrap yields a full prediction interval on the folded scale", {
  d   <- sim_sig_es(seed = 1)
  fit <- zcurve(yi = d$yi, sei = d$sei, boot_iter = 60,
                control = test_control(), show_plot = FALSE)
  pi  <- fit$effect_size$prediction_interval

  expect_named(pi, c("mu", "tau", "lb", "ub", "lb_het", "ub_het"))
  expect_true(all(is.finite(pi)))
  expect_gte(pi["tau"], 0)

  # Folded (magnitude) scale: lower bound cannot fall below 0, and the interval
  # has positive width.
  expect_gte(pi["lb"], 0)
  expect_gt(pi["ub"], pi["lb"])
})

test_that("estimation error widens the interval beyond heterogeneity alone", {
  # Small sample => appreciable sampling error in mu and tau, so folding it into
  # the interval visibly widens it beyond the heterogeneity-only version. The fit
  # is deterministic given the data and control seeds, so this margin is stable.
  d   <- sim_sig_es(n_total = 50, mu = 0.5, tau = 0.4, seed = 1)
  fit <- zcurve(yi = d$yi, sei = d$sei, boot_iter = 100,
                control = test_control(seed = 7), show_plot = FALSE)
  pi  <- fit$effect_size$prediction_interval

  width_full <- as.numeric(pi["ub"]     - pi["lb"])
  width_het  <- as.numeric(pi["ub_het"] - pi["lb_het"])
  expect_gt(width_full, width_het)
})

test_that("the prediction interval is far wider than the CI for the mean effect", {
  # The whole point: the CI for the average effect is narrow, but a new study's
  # true effect is highly uncertain because of heterogeneity.
  d   <- sim_sig_es(seed = 2)
  fit <- zcurve(yi = d$yi, sei = d$sei, boot_iter = 100,
                control = test_control(), show_plot = FALSE)
  pi      <- fit$effect_size$prediction_interval
  mean_ci <- fit$effect_size$mean_all          # c(point, ci_lb, ci_ub)

  pi_width      <- as.numeric(pi["ub"] - pi["lb"])
  mean_ci_width <- as.numeric(mean_ci[3] - mean_ci[2])
  expect_gt(pi_width, 1.5 * mean_ci_width)
})

test_that("without a bootstrap only the heterogeneity-only interval is available", {
  d   <- sim_sig_es(seed = 3)
  fit <- zcurve(yi = d$yi, sei = d$sei, boot_iter = 0, show_plot = FALSE)
  pi  <- fit$effect_size$prediction_interval

  expect_false(is.null(pi))
  expect_true(all(is.finite(pi[c("lb_het", "ub_het")])))
  expect_true(is.na(pi["lb"]) || !is.finite(pi["lb"]))
})

test_that("directional fit reports a signed prediction interval", {
  d   <- sim_sig_es(seed = 4, mu = 0.4, tau = 0.3)
  fit <- zcurve(yi = d$yi, sei = d$sei, directional = TRUE, folded = FALSE,
                boot_iter = 60, control = test_control(), show_plot = FALSE)
  pi  <- fit$effect_size$prediction_interval
  expect_true(all(is.finite(pi[c("lb", "ub")])))
  expect_gt(pi["ub"], pi["lb"])
})
