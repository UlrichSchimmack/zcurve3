# z-curve 3.0

Estimating statistical power, publication bias, and effect-size heterogeneity
from published significant test statistics.

*Ulrich Schimmack, František Bartoš, Jerry Brunner*

z-curve fits a flexible, distribution-free mixture model to the significant
z-values reported in a literature and returns the discovery, replication, and
false-discovery rates implied by the observed distribution of evidence — and,
when effect sizes are supplied, the effect-size distribution behind the
significant results.

---

## What you get

| Estimate | Meaning |
| --- | --- |
| **ODR** | Observed Discovery Rate — the proportion of tests that are significant. This is data, not a model estimate. |
| **EDR** | Expected Discovery Rate — the mean power of *all* conducted tests. `EDR < ODR` is the signature of selection for significance (publication bias / p-hacking). |
| **ERR** | Expected Replication Rate — the mean power of the *significant* tests; the probability that an exact replication of a significant study is again significant. |
| **FDR** | False Discovery Rate — the expected share of significant results that are false positives, implied by the EDR. |
| **Power H1 \| significant** | Mean power of the true-positive significant tests. |
| **NCP heterogeneity (tau)** | SD of the fitted non-centrality parameters. |

With `yi` / `sei` you additionally get the **effect-size distribution** — mean,
median, quartiles, and heterogeneity `tau` (among significant studies, and
selection-corrected among all conducted studies) — a **prediction interval** for
a new study, and per-study shrinkage-adjusted effects for the **forest plot**.

New in 3.0: effect-size estimation and heterogeneity, a prediction interval for a
new study, directional and clustered analyses, and a rewritten forest plot. See
[NEWS.md](NEWS.md).

---

## Install

Not yet on CRAN. Install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("UlrichSchimmack/zcurve3")
library(zcurve3)
```

z-curve 3.0 is a **separate package** from `zcurve` (z-curve 2.0): `zcurve`
keeps backward compatibility, `zcurve3` adds the effect-size, directional,
clustered, and forest-plot features. The two share no code and can be installed
side by side.

---

## Quick start

```r
# z-values from a literature (significant and non-significant)
z <- abs(rnorm(2000, mean = 2.5))

fit <- zcurve(zval = z, boot_iter = 500)
fit                 # prints the estimate table
plot(fit)           # fitted density with the estimate block
summary(fit)        # + components, local power, local effect sizes
```

Set `boot_iter = 0` (the default) for a fast point-estimate-only fit; use `500+`
for reported confidence intervals.

---

## Data inputs

Supply exactly one consistent combination of test statistics:

| You have | Pass | Notes |
| --- | --- | --- |
| z-values | `zval` | The native input. |
| t-values | `tval`, `df` | Converted to z internally. |
| p-values | `pval` | Two-sided; converted via `qnorm(1 - p/2)`. |
| effect + SE | `yi`, `sei` | z is taken as `yi / sei`. |

`yi` and `sei` may be **added to any** of the above. **They are required for the
effect-size estimates and for the forest plot** — without them the model still
returns power/bias estimates but no effect-size table and no individual effects.

Optional: `study_id` labels studies (used in the forest plot); `cluster_id`
groups dependent tests (see [Clustered data](#clustered-data)).

---

## Reading the output

`print(fit)` shows the **Estimates** table above (with bootstrap CIs when
`boot_iter > 0`) and, when `yi`/`sei` were supplied, an **Effect sizes among
significant studies** table: Mean, Median, 25th/75th percentiles, and
Heterogeneity (`tau`).

`summary(fit)` adds the fitted mixture components, local power by z-interval,
local effect sizes / heterogeneity, and — when the fit is bootstrapped — the
**prediction interval** below.

---

## Prediction interval

With `yi`/`sei` and `boot_iter > 0`, `summary(fit)` and
`fit$effect_size$prediction_interval` report a **prediction interval** for the
true effect of a *new* study from the same population — the interval that
contains ~95% of the population effect sizes, not the (much narrower) confidence
interval for the average.

It is built from the **selection-corrected** normal random-effects fit (`mu`,
`tau`) and pooled across the bootstrap, so it folds in the sampling error in
**both** `mu` and `tau` on top of the heterogeneity itself. On the folded (`|d|`)
scale the lower bound cannot fall below 0 ("no effect"); in a directional fit it
can go negative (a sign error).

```
Prediction interval for a new study (95% of population effects; mu = 0.26, tau = 0.35):
  [0.02, 1.02]   (heterogeneity + sampling error in mu and tau)
```

A wide interval is the point: when heterogeneity is large the average says little
about the next study, and the individual studies (the forest plot) are where the
evidence is. The returned vector also carries `lb_het`/`ub_het` — the same
interval with `mu`/`tau` treated as known (no sampling error) — for comparison.

---

## The main plot — `plot(fit)`

`plot.zcurve()` draws the histogram of significant z-values, the fitted density,
and the estimate block.

```r
plot(fit,
     xlim = c(0, 8),
     show_ci_band  = TRUE,    # grey pointwise uncertainty band around the curve
     show_edr_band = TRUE)    # orange curves at the 2.5 / 97.5% EDR bootstrap reps
```

| Argument | Default | Effect |
| --- | --- | --- |
| `histogram_col` | `"blue3"` | Histogram bar colour. |
| `curve_col` | `"red"` | Fitted density colour. |
| `histogram_width` | `0.2` | Bar width. |
| `xlim`, `ylim` | `c(0,6)`, `c(0,0.6)` | Axis ranges. |
| `show_text` | `TRUE` | Show the ODR / EDR / ERR / FDR estimate block. |
| `show_local_power` | `TRUE` | Annotate local power under the curve. |
| `show_ci_band` | `TRUE` | Pointwise bootstrap density band (needs `boot_iter > 0`). |
| `show_edr_band` | `FALSE` | Overlay the fitted curves at the extreme EDR bootstrap replicates. |
| `ci_level` | `0.95` | Band / CI level. |
| `ci_band_col`, `edr_band_col` | `"grey70"`, `"darkorange"` | Band colours. |
| `line_width`, `text_size` | `4`, `1` | Curve thickness / text scaling. |

The estimate block prints bootstrap CIs in brackets when the model was fit with
`boot_iter > 0`, with the confidence-level header centred over the interval
columns. When `cluster_id` is supplied, the number of clusters is shown
alongside the number of tests.

**Remembering plot options.** Any of these options can be set once on the fit via
`zcurve(..., plot_control = list(ylim = c(0, 0.9), histogram_width = 0.15))`.
They style the automatic plot drawn during the fit and are stored on the object,
so later `plot(fit)` calls reuse the same look — an explicit `plot(fit, ...)`
argument still overrides.

---

## The forest plot — `zcurve_forest(fit)`

The forest plot shows, for each individual study, its **shrinkage-adjusted**
effect size — the observed effect pulled toward the fitted mixture — with a
credible interval, alongside its **adjusted power** (the replication
probability) and the minimum-effect line.

**Requires a bootstrapped fit:** run `zcurve()` with `yi`, `sei`, **and
`boot_iter > 0`**, so the adjusted-effect intervals reflect the uncertainty in
the fitted population, not just each study's own standard error. Otherwise the
call errors.

```r
fit <- zcurve(yi = d, sei = se, study_id = id, boot_iter = 500)

zcurve_forest(fit)                       # draw to the current device
zcurve_forest(fit, file = "forest.png")  # or auto-size and save (recommended)
# forest.zcurve(fit)                     # identical — the method form
```

> There is no bare `forest()` generic in this package, so call
> `zcurve_forest(fit)` (or `forest.zcurve(fit)`) rather than `forest(fit)`.

Four columns are drawn: an **id** column (`study_id`) | the **Study** labels |
the **forest** (adjusted effect ● with its interval, observed effect ○, and the
minimum-effect line) | an **estimates** column (adjusted **Power** — or observed
**z** — then the adjusted effect `[95% CI]`).

**Auto-sizing.** Passing `file = "forest.png"` opens a device sized to the study
count so rows never collapse into each other; the height grows with the number
of studies and the text size. Drawing into a fixed device instead is fine for
small sets and warns (with a recommended height) when it would be cramped.
Format is taken from the extension (`png`, `jpeg`, `tiff`, `pdf`, `svg`).

| Argument | Default | Effect |
| --- | --- | --- |
| `labels` | study id | Descriptive row labels for the Study column: **named by `study_id`**, **paired with `label_id`**, or **one label per study in fit order**. Long labels are cut at the first `":"` and packed to whole words within `label_chars`. |
| `label_id` | `NULL` | Optional `study_id`s, one per `labels` entry, so you can write `labels = titles, label_id = ids` instead of `setNames(titles, ids)`. |
| `label_chars` | `50` | Maximum label length in characters (`NULL` = untouched). |
| `stat` | `"power"` | Statistic shown beside each effect: `"power"` (adjusted replication probability, integer %) or `"z"` (observed z). |
| `z_min` | `4` | Show only studies with \|z\| > `z_min`. |
| `es_lb_min`, `es_lb_max` | `0.2`, `Inf` | Keep only studies whose adjusted-effect **lower bound** is in `[es_lb_min, es_lb_max]`. |
| `k_max` | `30` | Show at most this many studies (top `k_max` by `sort_by`). |
| `min_effect` | fit's `min_effect` (`0.20`) | Minimum-effect line; changeable here **without refitting**. |
| `sort_by` | `"lower_bound"` | One of `lower_bound`, `prob_meaningful`, `adjusted_effect`, `z`, `study_id`. |
| `decreasing` | `TRUE` | Sort direction. |
| `show_raw` | `TRUE` | Draw observed (unadjusted) effects as open circles. |
| `show_id` | `TRUE` | Draw the separate id column. |
| `text_size` | `1` | Multiplier for all row / header text and point sizes. |
| `forest_frac` | `0.26` | Minimum share of the figure width reserved for the forest panel (labels truncate to keep it). |
| `label_max_frac` | `0.5` | Cap on the label column as a fraction of figure width. |
| `file` | `NULL` | Output path; when set, the plot is saved to an auto-sized device. |
| `width`, `height`, `res` | `NULL`, `NULL`, `120` | Device size (inches) / resolution for `file` output; `height` auto-sizes to the row count when `NULL`. |
| `row_height` | `NULL` | Inches per row for the auto-sized height (`NULL` = from `text_size`). |
| `xlim`, `digits` | auto, `2` | Effect-axis range; rounding in the interval column. |
| `point_col`, `raw_col`, `min_effect_col` | `"blue3"`, `"grey60"`, `"red3"` | Colours. |
| `panel_widths` | `c(1.9, 5.7, 1.9)` | Fallback relative widths (labels, forest, estimates), used only when auto-sizing is unavailable. |

```r
# top 40 studies by adjusted lower bound, saved at an auto-sized height
zcurve_forest(fit, k_max = 40, es_lb_min = 0.1, file = "forest.png")

# descriptive labels (named by study_id), showing observed z instead of power
zcurve_forest(fit, labels = setNames(titles, ids), stat = "z")
```

Because the adjusted effects come from the fitted posterior, changing
`min_effect` at plot time re-computes the meaningful-effect probability without
refitting. `zcurve_forest()` returns (invisibly) the plotted data frame —
including `study_id`, `cluster_id`, and `power_adjusted`.

---

## Directional vs. folded (nondirectional)

- **`folded = TRUE`, `directional = FALSE`** (default): the sign of the effect is
  ignored and both significant tails inform the fit; effects are reported on the
  absolute scale (`|d|`). This is the usual meta-science setting.
- **`directional = TRUE`, `folded = FALSE`**: the sign is retained; use when the
  direction is meaningful and consistent across studies.

In a directional fit the local-power annotations under `plot(fit)` are
**one-sided** (power in the predicted direction), so a study observed in the
negative tail shows its small chance of replicating significant in the predicted
direction — a sign error — rather than a mirrored two-sided power that rises into
the negative range.

**Negative components need no selection.** Negative `ncp` values are only
identified without selection: with a selection window (`int_beg > 0`) the fit
conditions on the significant tail and cannot separate `ncp = 0` from `ncp < 0`,
so a negative-`ncp` grid under selection is rejected. To model negative effects
(the genomics / no-selection setting) open the window down to the components,
e.g. `int_beg = min(ncp)`.

---

## Clustered data

When tests are nested (several tests per study, lab, or paper), pass
`cluster_id`. The bootstrap then resamples whole clusters, so dependence does not
deflate the confidence intervals.

`study_id` and `cluster_id` are independent: **`study_id` labels each individual
test** (one forest row per test) while **`cluster_id` defines the clusters** the
bootstrap resamples. Both are carried into `fit$individual_effects`, so the
forest keeps one row per test and you can see cluster membership via `labels` or
the returned data frame.

```r
fit <- zcurve(yi = d, sei = se, study_id = test_id, cluster_id = paper_id,
              boot_iter = 500)

# show the paper each test belongs to
zcurve_forest(fit, labels = paste0("t", fit$individual_effects$study_id,
                                   " · paper ", fit$individual_effects$cluster_id))
```

---

## Fitting control — `zcurve_control()`

Tuning parameters are passed via `control = zcurve_control(...)`.

| Argument | Default | Purpose |
| --- | --- | --- |
| `boot_iter` | `0` | Bootstrap replicates (500+ for final models). Set here **or** on `zcurve()`, not both. |
| `parallel`, `cores` | `TRUE`, `NULL` | Parallel bootstrap; `NULL` auto-picks a conservative worker count. |
| `seed` | `NULL` | Reproducible bootstrap. |
| `tol_criterion`, `max_iter`, `max_iter_boot` | `1e-6`, `2000`, `500` | EM convergence threshold / iteration caps (point fit and per-replicate). |
| `ci_alpha` | `.05` | CI level (95%). |
| `augment`, `n_bars`, `bw_est`, `spline_width` | `TRUE`, `512`, `0.05`, `.5` | Density-method (OF) tuning. |
| `density_step`, `bootstrap_density_step` | `0.01`, `0.05` | Numerical density-grid step for the point fit / bootstrap fits. |
| `floor_correct` | `TRUE` | Remove the homogeneous-null floor from `es_tau_sig` (see below). |
| `floor_reps` | `5` | Homogeneous-null refits averaged to estimate that floor. |
| `es_null_share` | `0.5` | Individual-effects prior only: give the null component at least this share of the low-power (ncp ≤ 1) mass, so genuinely-null studies can shrink to 0 in the forest plot. Does not affect EDR / ERR / FDR. |

Plot styling is set separately, on `zcurve()` itself, via `plot_control` (see
[The main plot](#the-main-plot--plotfit)).

`zcurve()` validates the component grid up front: `ncp` must be finite and
non-empty, and `z_sd` must have the same length as `ncp` and be `>= 1`. Supplying
your own components — including varying means *and* SDs — is fully supported;
only inconsistent input is rejected.

---

## Estimation methods

`est_method`:

- **`"OF"`** (default) — density/KDE-based fit; robust and roughly flat in the
  number of tests.
- **`"EM"`** — likelihood-based mixture; better at small numbers of tests.
- **`"SQP"`, `"ML_gamma"`** — additional fitters.

---

## Effect-size heterogeneity and the floor correction

`es_tau_sig` (the *Heterogeneity (tau)* row of the effect-size table) is the SD
of true effect sizes among significant studies, estimated from the
distribution-free mixture — **no normal-distribution assumption**.

Heterogeneous standard errors alone can make the mixture report apparent
effect-size heterogeneity even when the true effects are homogeneous. The floor
correction estimates that artefact with a *plug-in homogeneous null* (a constant
effect at the fitted mean, resimulated with the observed standard errors and the
same selection, refit through the same mixture) and removes it with a
variance-share blend:

```
tau_adj = sqrt(max(0, tau^2 - floor^4 / tau^2))
```

The blend has no tuning constant: it removes the full floor when the estimate is
near it (true `tau ≈ 0` collapses to `0`) and tapers quartically, leaving genuine
high heterogeneity essentially untouched. It is **conservative at high tau** — an
identifiability limit of a significant-only, selected sample, documented in
[NEWS.md](NEWS.md). Toggle with `floor_correct` / `floor_reps`.

---

## Citation

Schimmack, U., Bartoš, F., & Brunner, J. (2026). *z-curve 3.0: Estimating power,
publication bias, and effect-size heterogeneity from significant test
statistics.*
