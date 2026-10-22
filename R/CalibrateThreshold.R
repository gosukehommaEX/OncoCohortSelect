#' Threshold of a decision rule for a given false selection probability
#'
#' @description
#' Finds, from the results of \code{\link{SimSelection}} under a scenario in
#' which the treatment cohort should not be selected (for example identical
#' cohorts), the smallest threshold for which the proportion of simulated
#' trials that select the treatment cohort is at most \code{alpha}. Decision
#' rules based on different statistics can then be compared at the same false
#' selection probability.
#'
#' @details
#' The decision rules are those of \code{\link{SelectionOC}}. With
#' \code{statistic = "br_diff"} and \code{admissibility = TRUE}, trials in
#' which only the treatment cohort is admissible select it whatever the
#' threshold; when their proportion exceeds \code{alpha}, no threshold
#' achieves \code{alpha} and the result is \code{NA} with a warning. The
#' threshold is one of the simulated values of the statistic (or \code{-Inf}
#' when no trial needs to be excluded), and the achieved proportion can be
#' smaller than \code{alpha} because of ties and the finite number of trials.
#'
#' @param results Data frame returned by \code{\link{SimSelection}}.
#' @param statistic One of \code{"br_diff"}, \code{"br_ref"}, \code{"ntb"},
#'   \code{"ntb_lower"}, \code{"wr"} and \code{"wo"}.
#' @param alpha Target probability of selecting the treatment cohort.
#' @param admissibility Logical: use the admissibility of the benefit-risk
#'   scores (\code{"br_diff"} and \code{"br_ref"} only).
#' @return A data frame with columns \code{statistic}, \code{alpha},
#'   \code{threshold} and \code{p_treatment} (the achieved proportion).
#' @examples
#' set.seed(1)
#' res <- data.frame(ntb = rnorm(1000, 0, 0.1), wr = exp(rnorm(1000, 0, 0.3)))
#' CalibrateThreshold(res, "ntb", alpha = 0.1)
#' CalibrateThreshold(res, "wr", alpha = 0.1)
#' @seealso \code{\link{SelectionOC}}, \code{\link{SimSelection}}
#' @export
CalibrateThreshold <- function(results, statistic = c("br_diff", "br_ref", "ntb",
                                                      "ntb_lower", "wr", "wo"),
                               alpha = 0.05, admissibility = TRUE) {
  if (!is.data.frame(results) || nrow(results) == 0L) {
    stop("'results' must be a data frame with at least one row.", call. = FALSE)
  }
  statistic <- match.arg(statistic)
  if (!is.numeric(alpha) || length(alpha) != 1L || is.na(alpha) || alpha <= 0 ||
      alpha >= 1) {
    stop("'alpha' must be in (0, 1).", call. = FALSE)
  }
  if (!is.logical(admissibility) || length(admissibility) != 1L || is.na(admissibility)) {
    stop("'admissibility' must be TRUE or FALSE.", call. = FALSE)
  }
  s <- results[[statistic]]
  if (is.null(s)) stop("'results' has no column '", statistic, "'.", call. = FALSE)
  .check_adm(results, statistic, admissibility)
  N <- nrow(results)
  fixed <- rep(FALSE, N)
  eligible <- !is.na(s)
  if (admissibility && statistic == "br_diff") {
    at <- results$adm_trt %in% TRUE
    ac <- results$adm_ctl %in% TRUE
    fixed <- at & !ac
    eligible <- eligible & at & ac
  } else if (admissibility && statistic == "br_ref") {
    eligible <- eligible & results$adm_ref %in% TRUE
  }
  # number of eligible trials that may exceed the threshold
  k <- floor(alpha * N - sum(fixed) + 1e-8)
  if (k < 0) {
    warning("The trials that select the treatment cohort whatever the threshold ",
            "exceed 'alpha'.", call. = FALSE)
    thr <- NA_real_
    p <- sum(fixed) / N
  } else {
    v <- sort(s[eligible], decreasing = TRUE)
    thr <- if (k >= length(v)) -Inf else v[k + 1L]
    p <- mean(.rule_select(results, statistic, thr, admissibility) == "treatment")
  }
  data.frame(statistic = statistic, alpha = alpha, threshold = thr, p_treatment = p,
             stringsAsFactors = FALSE)
}
