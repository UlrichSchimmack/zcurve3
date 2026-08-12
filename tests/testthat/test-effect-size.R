# Effect-size estimation from yi/sei: table shape, per-study effects, and the
# selection-correction / shrinkage invariants that motivate the method.

test_that("supplying yi/sei produces an effect-size table", {
  d   <- sim_sig_es(seed = 1)
  fit <- zcurve(yi = d$yi, sei = d$sei, boot_iter = 0, show_plot = FALSE)

  expect_false(is.null(fit$effect_size))
  expect_true(all(c("mean_all", "mean_significant",
                    "heterogeneity_significant", "heterogeneity") %in%
                  names(fit$effect_size)))
  # Each estimate is a c(point, ci_lb, ci_ub) vector; the point estimate is [1]
  # (the CI is NA without a bootstrap).
  expect_true(is.finite(fit$effect_size$mean_significant[1]))
  expect_gte(fit$effect_size$heterogeneity[1], 0)
})

test_that("selection correction pulls the mean below the naive significant mean", {
  # Studies are selected for significance, which inflates the observed mean; the
  # all-studies (debiased) mean must sit at or below the significant-only mean.
  d   <- sim_sig_es(seed = 2)
  fit <- zcurve(yi = d$yi, sei = d$sei, boot_iter = 0, show_plot = FALSE)
  expect_lte(fit$effect_size$mean_all[1], fit$effect_size$mean_significant[1] + 1e-8)
})

test_that("individual_effects has one row per test with the expected columns", {
  # Per-study adjusted effects and their intervals come from the bootstrap
  # posterior, so a bootstrap is required for them to be populated.
  d   <- sim_sig_es(seed = 3)
  fit <- zcurve(yi = d$yi, sei = d$sei, boot_iter = 40,
                control = test_control(), show_plot = FALSE)
  ie  <- fit$individual_effects

  expect_s3_class(ie, "data.frame")
  expect_equal(nrow(ie), length(d$yi))
  expect_true(all(c("study_id", "effect_observed", "effect_adjusted",
                    "effect_adjusted_lb", "effect_adjusted_ub",
                    "power_adjusted") %in% names(ie)))

  expect_true(all(ie$power_adjusted >= 0 & ie$power_adjusted <= 1))
  expect_true(all(ie$effect_adjusted_lb <= ie$effect_adjusted + 1e-8))
  expect_true(all(ie$effect_adjusted_ub >= ie$effect_adjusted - 1e-8))
})

test_that("adjusted per-study effects shrink (less dispersed than observed)", {
  d   <- sim_sig_es(seed = 4)
  fit <- zcurve(yi = d$yi, sei = d$sei, boot_iter = 40,
                control = test_control(), show_plot = FALSE)
  ie  <- fit$individual_effects
  expect_lt(stats::sd(ie$effect_adjusted), stats::sd(ie$effect_observed))
})
