# zcurve3 3.0 (in development)

Major update to the z-curve method, released as a **new, standalone package**
(`zcurve3`) separate from `zcurve` (z-curve 2.0); the two share no code and can
be installed side by side. Power estimation (EDR/ERR/FDR) keeps the flexible
mixture approach of z-curve 2.0. New in 3.0: effect-size estimation and
heterogeneity, a prediction interval for a new study, directional and clustered
analyses, and a rewritten forest plot.

## Estimation

* `es_tau_sig` — the heterogeneity (SD) of true effect sizes among significant
  results — is estimated from the **distribution-free ncp mixture**, so no
  parametric form is assumed for the effect-size distribution. A normal
  random-effects alternative was evaluated during development and rejected: it
  reintroduced a distributional assumption and failed on bimodal / high
  false-discovery-rate data, which the mixture handles natively.

* **New floor correction for `es_tau_sig`.** Heterogeneous standard errors make
  the mixture report apparent effect-size heterogeneity even when the true
  effects are homogeneous. The correction estimates that floor by a *plug-in
  homogeneous null* — a constant effect at the fitted mean, simulated with the
  observed standard errors and the same selection, refit through the same
  mixture — and removes it with a variance-share blend:

  ```
  tau_adj = sqrt(max(0, tau^2 - floor^4 / tau^2))
  ```

  The blend has no tuning constant. It removes the full floor when the estimate
  is near it (true tau ~ 0 collapses to 0) and tapers quartically, so genuine
  high heterogeneity is left essentially untouched.

* Known limit (documented, not a defect): heterogeneity estimated from a
  significant-only, selected sample is **conservative at high tau** — the
  estimate under-states large heterogeneity somewhat. This is an identifiability
  limit of the selected sample, not of the model: it is unchanged by widening or
  refining the component grid.

## Prediction interval

* **New.** `summary(fit)` and `fit$effect_size$prediction_interval` report a
  **prediction interval** for the true effect of a *new* study from the same
  population — the interval containing ~95% of the population effect sizes, not
  the (much narrower) confidence interval for the average. Requires `yi`/`sei`
  and `boot_iter > 0`.
* It is built from the **selection-corrected normal random-effects fit** (the
  mean and tau of the all-studies distribution) and pooled across the bootstrap,
  so the sampling error in *both* the mean and tau widens it on top of the
  heterogeneity itself. Folded fits report it on the `|d|` scale (lower bound
  cannot fall below 0); directional fits can go negative (a sign error). The
  returned vector also carries `lb_het` / `ub_het`, the same interval with the
  mean and tau treated as known (no sampling error), for comparison.

## New control options

* `zcurve_control()` gains `floor_correct` (default `TRUE`) and `floor_reps`
  (default `5`, the number of homogeneous-null refits averaged for the floor).
* `zcurve_control()` also gains `es_null_share` (default `0.5`), which reserves a
  share of the low-power (ncp ≤ 1) mass for the null component in the
  **individual-effects prior only**, so genuinely-null studies can shrink to 0 in
  the forest plot. It does not move EDR / ERR / FDR.
* `zcurve()` gains `plot_control`, a list of `plot.zcurve()` options used for the
  automatic plot drawn during the fit and stored on the object, so later
  `plot(fit)` calls reuse the same look; an explicit `plot(fit, ...)` argument
  still overrides. Unknown option names are rejected up front.

## Input validation

* `zcurve()` now validates the component grid up front: `ncp` must be finite and
  non-empty, and `z_sd` must have the same length as `ncp` and be `>= 1`.
  Supplying your own components — including varying means *and* SDs — remains
  fully supported; only inconsistent input is rejected. Previously a length
  mismatch produced a silently wrong fit instead of an error.
* Negative `ncp` components are now rejected under selection (`int_beg > 0`),
  where they are unidentified — the fit conditions on the significant tail and
  cannot separate `ncp = 0` from `ncp < 0`. To model negative effects, run
  without selection (`int_beg <= min(ncp)`), as in the genomics setting where the
  full distribution of tests is observed.

## Nondirectional (folded) analyses

* Input is now folded internally when `folded = TRUE`, so **both** significant
  tails contribute to the fit. Previously signed input was used as supplied, so
  only the positive significant tail entered the fit and the plotted density was
  drawn symmetric over signed data.

## Directional analyses

* The plotted density is no longer mirrored about zero for directional fits, so
  the fitted curve sits over the data instead of being forced symmetric.
* Local power under `plot(fit)` is now **one-sided** (power in the predicted
  direction) for a directional fit, so a study in the negative tail shows its
  small chance of replicating significant in the predicted direction — a sign
  error — instead of a mirrored two-sided power that (wrongly) rose into the
  negative range.

## Clustered analyses

* Fixed the cluster bootstrap for `est_method = "OF"`: a misspelled `unlist()`
  argument caused every bootstrap replicate to fail ("All bootstrap runs
  failed"). The EM and ML paths were unaffected.
* The plot reports the number of clusters when `cluster_id` is supplied.
* `study_id` and `cluster_id` are now fully separate end to end. `cluster_id`
  gets the same up-front length check as `study_id` (previously it was only
  validated inside the bootstrap, so a wrong-length vector could silently
  misalign when `boot_iter = 0`), and it is carried into
  `fit$individual_effects` alongside `study_id`. The forest plot keeps one row
  per test, labelled by `study_id`, with cluster membership available.

## Plot

* Bootstrap confidence intervals are shown beside ODR / EDR / ERR / FDR.
* The estimate block is column-aligned (fixed-width), with the confidence-level
  header centred over the interval columns.
* Optional pointwise bootstrap density band (`show_ci_band`).
* The automatic plot drawn by `show_plot = TRUE` now uses the analysis range
  (`x_lim_min` / `x_lim_max`) rather than always starting at zero.
* `version` and `date` shown on the plot are arguments of `zcurve()`.

## Forest plot

* **Now requires a bootstrapped fit** (`boot_iter > 0`): the adjusted-effect
  intervals reflect the uncertainty in the fitted population, not just each
  study's own standard error. Fitting without the bootstrap and calling
  `zcurve_forest()` errors.
* **Four columns**: a separate **id** column (`study_id`), the **Study** labels,
  the forest, and an estimates column showing the adjusted **power** (the
  replication probability, `stat = "power"`, the default) or observed **z**
  (`stat = "z"`) next to the adjusted effect `[95% CI]`. The old
  `P(|d| > min)` column was dropped. `power_adjusted` is added to the returned
  data frame (alongside `study_id` and `cluster_id`).
* **Auto-sizing to a file**: `zcurve_forest(fit, file = "forest.png")` opens a
  device sized to the study count — the height grows with the number of rows and
  the text size, so rows never collapse into each other — and saves it. Format is
  taken from the extension (`png`, `jpeg`, `tiff`, `pdf`, `svg`), with `width`,
  `height`, `res`, and `row_height` to tune. Drawing into a fixed device warns
  (with a recommended height) when it would be cramped. (An earlier attempt to
  auto-size via `dev.new()` for an on-screen window was removed — it produced a
  clipped, half-drawn plot on some platforms.)
* **New selection / label arguments**: `es_lb_min` / `es_lb_max` (keep studies
  whose adjusted-effect lower bound is in a window), `k_max` (cap the number of
  studies shown), `label_chars` (label length, default 50; long labels are cut at
  the first `":"` and packed to whole words), `show_id`, `stat`, `forest_frac`
  (minimum forest-panel width), and `label_max_frac` (label-column cap). Column
  widths are auto-sized; `panel_widths` is now only a fallback.
* `labels` accepts a vector named by `study_id` or one label per study in fit
  order; `text_size` scales all row/header text and point sizes.
