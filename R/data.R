#' Elderly-priming studies
#'
#' Reported effect sizes from 17 tests of behavioural "elderly priming" -- the
#' claim that subtly activating the elderly stereotype (with words such as
#' *Florida*, *bingo*, or *wrinkle*) makes people walk more slowly or otherwise
#' behave in stereotype-consistent ways. The set collects the original
#' Bargh, Chen and Burrows (1996) experiments together with later direct and
#' conceptual replications, including the widely cited non-replication of
#' Doyen, Klein, Pichon and Cleeremans (2012). Only 6 of the 17 tests are
#' significant, which makes it a compact, real-world illustration of a selected,
#' low-powered literature.
#'
#' @format A data frame with 17 rows and 5 variables:
#' \describe{
#'   \item{study}{Study label (article and experiment).}
#'   \item{d}{Observed standardized effect size (Cohen's \eqn{d}), signed so that
#'     positive values are stereotype-consistent.}
#'   \item{se}{Standard error of \code{d}.}
#'   \item{z}{z-score, \code{d / se}.}
#'   \item{sig}{Logical; significant at two-sided \eqn{\alpha = 0.05}
#'     (\code{abs(z) > 1.96}).}
#' }
#' @source Effect sizes compiled from the published reports of the listed
#'   studies. The seminal study is Bargh, Chen and Burrows (1996); the
#'   best-known failed replication is Doyen, Klein, Pichon and Cleeremans (2012).
#' @references
#' Bargh, J. A., Chen, M., & Burrows, L. (1996). Automaticity of social
#' behavior: Direct effects of trait construct and stereotype activation on
#' action. *Journal of Personality and Social Psychology*, 71(2), 230-244.
#'
#' Doyen, S., Klein, O., Pichon, C.-L., & Cleeremans, A. (2012). Behavioral
#' priming: It's all in the mind, but whose mind? *PLoS ONE*, 7(1), e29081.
#' @examples
#' data(elderly_priming)
#' head(elderly_priming)
#' table(elderly_priming$sig)
"elderly_priming"
