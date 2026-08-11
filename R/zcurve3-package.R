#' zcurve3: Power, Publication Bias, and Effect-Size Heterogeneity from
#' Significant Test Statistics
#'
#' Fits a flexible, distribution-free mixture model to the significant z-values
#' reported in a literature and returns the discovery, replication, and
#' false-discovery rates implied by the observed distribution of evidence -- and,
#' when effect sizes are supplied, the effect-size distribution behind the
#' significant results, including per-study shrinkage-adjusted effects and a
#' forest plot.
#'
#' z-curve 3.0 is a **separate package** from the `zcurve` package (z-curve 2.0):
#' the two share no code and can be installed side by side. `zcurve` keeps
#' backward compatibility; `zcurve3` adds the effect-size, directional, clustered,
#' and forest-plot features.
#'
#' @section Main functions:
#' - [zcurve()] -- fit the model.
#' - [zcurve_control()] -- tuning parameters passed via `control`.
#' - [plot.zcurve()] -- the fitted-density plot with the estimate block.
#' - [zcurve_forest()] -- the minimum-effect forest plot of individual studies.
#'
#' @keywords internal
#' @import stats graphics grDevices utils parallel
#' @importFrom tools file_ext
#' @importFrom KernSmooth bkde
"_PACKAGE"
