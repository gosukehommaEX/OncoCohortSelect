#' Threshold of a decision rule for a given false selection probability
#'
#' @description
#' Finds, from the results of \code{\link{SimSelection}} under a scenario in
#' which no cohort should be selected over the reference cohort (for example
#' cohorts that are all identical), the smallest threshold for which the
#' proportion of simulated trials that select a cohort other than the
#' reference is at most \code{alpha}. Decision rules based on different
#' statistics can then be compared at the same false selection probability.
#'
#' @details
#' The decision rules are those of \code{\link{SelectionOC}}: a cohort other
#' than the reference is selected when the largest statistic among the
#' candidate cohorts exceeds the threshold. With \code{statistic = "br_diff"},
#' \code{admissibility = TRUE} and \code{ref.inadmissible = "switch"}, trials
#' in which the reference cohort is not admissible and another cohort is
#' admissible select that cohort whatever the threshold; when their proportion
#' exceeds \code{alpha}, no threshold achieves \code{alpha} and the result is
#' \code{NA} with a warning. With \code{ref.inadmissible = "keep"}, every
#' selection of another cohort needs the threshold, so a threshold that
#' achieves \code{alpha} always exists. The threshold is
#' one of the simulated values of the statistic (or \code{-Inf} when no trial
#' needs to be excluded), and the achieved proportion can be smaller than
#' \code{alpha} because of ties and the finite number of trials.
#'
#' @param results Data frame returned by \code{\link{SimSelection}}.
#' @param statistic One of \code{"br_diff"}, \code{"br_ref"}, \code{"ntb"},
#'   \code{"ntb_lower"}, \code{"wr"} and \code{"wo"}.
#' @param alpha Target probability of selecting a cohort other than the
#'   reference.
#' @param admissibility Logical: use the admissibility of the benefit-risk
#'   scores (\code{"br_diff"} and \code{"br_ref"} only).
#' @param ref.inadmissible \code{"switch"} or \code{"keep"}: the rule of
#'   \code{"br_diff"} with admissibility when the reference cohort is not
#'   admissible (see \code{\link{SelectionOC}}).
#' @return A data frame with columns \code{statistic}, \code{alpha},
#'   \code{threshold} and \code{p_nonreference} (the achieved proportion of
#'   trials that select a cohort other than the reference).
#' @examples
#' set.seed(1)
#' res <- data.frame(sim = rep(1:500, each = 3), group = rep(c("A", "B", "C"), 500),
#'                   is_reference = rep(c(TRUE, FALSE, FALSE), 500))
#' res$ntb <- ifelse(res$is_reference, NA, rnorm(1500, 0, 0.1))
#' res$wr <- ifelse(res$is_reference, NA, exp(rnorm(1500, 0, 0.3)))
#' CalibrateThreshold(res, "ntb", alpha = 0.1)
#' CalibrateThreshold(res, "wr", alpha = 0.1)
#' @seealso \code{\link{SelectionOC}}, \code{\link{SimSelection}}
#' @export
CalibrateThreshold <- function(results, statistic = c("br_diff", "br_ref", "ntb",
                                                      "ntb_lower", "wr", "wo"),
                               alpha = 0.05, admissibility = TRUE,
                               ref.inadmissible = c("switch", "keep")) {
  statistic <- match.arg(statistic)
  ref.inadmissible <- match.arg(ref.inadmissible)
  if (!is.numeric(alpha) || length(alpha) != 1L || is.na(alpha) || alpha <= 0 ||
      alpha >= 1) {
    stop("'alpha' must be in (0, 1).", call. = FALSE)
  }
  if (!is.logical(admissibility) || length(admissibility) != 1L || is.na(admissibility)) {
    stop("'admissibility' must be TRUE or FALSE.", call. = FALSE)
  }
  # the threshold does not change which trials have candidates whatever the
  # threshold ('fixed') nor the largest statistic of the candidates ('max')
  rs <- .rule_select(results, statistic, Inf, admissibility, ref.inadmissible)
  N <- nrow(rs)
  # number of trials without a fixed selection that may exceed the threshold
  k <- floor(alpha * N - sum(rs$fixed) + 1e-8)
  if (k < 0) {
    warning("The trials that select a cohort other than the reference whatever the ",
            "threshold exceed 'alpha'.", call. = FALSE)
    thr <- NA_real_
    p <- sum(rs$fixed) / N
  } else {
    v <- sort(rs$max[!rs$fixed & rs$max > -Inf], decreasing = TRUE)
    thr <- if (k >= length(v)) -Inf else v[k + 1L]
    sel <- .rule_select(results, statistic, thr, admissibility, ref.inadmissible)
    ref <- results$group[results$is_reference]
    names(ref) <- as.character(results$sim[results$is_reference])
    p <- mean(!is.na(sel$selected) & sel$selected != ref[as.character(sel$sim)])
  }
  data.frame(statistic = statistic, alpha = alpha, threshold = thr, p_nonreference = p,
             stringsAsFactors = FALSE)
}
