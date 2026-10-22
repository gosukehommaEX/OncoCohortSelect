#' Selection probabilities of a decision rule
#'
#' @description
#' Computes, from the results of \code{\link{SimSelection}}, the proportions of
#' simulated trials in which a decision rule selects the treatment cohort, the
#' control cohort or neither.
#'
#' @details
#' The treatment cohort is selected when \code{statistic} exceeds
#' \code{threshold}; otherwise the control cohort is selected. The statistics
#' are
#' \itemize{
#'   \item \code{"br_diff"}: the difference of the benefit-risk scores against
#'     target values. With \code{admissibility = TRUE}, the scores are compared
#'     only when both cohorts are admissible; an admissible cohort is selected
#'     over one that is not, and neither is selected when neither is
#'     admissible.
#'   \item \code{"br_ref"}: the benefit-risk score of the treatment cohort
#'     relative to the control cohort. With \code{admissibility = TRUE}, the
#'     treatment cohort must also be admissible relative to the control cohort.
#'   \item \code{"ntb"}, \code{"ntb_lower"}, \code{"wr"}, \code{"wo"}: the net
#'     treatment benefit, its lower confidence bound, the win ratio and the win
#'     odds.
#' }
#' A missing statistic (for example a win ratio when no pair is decided)
#' selects the control cohort. The default thresholds are 0 for the
#' differences and the net treatment benefit and 1 for the win ratio and the
#' win odds; \code{"br_ref"} has no default.
#'
#' @param results Data frame returned by \code{\link{SimSelection}}.
#' @param statistic One of \code{"br_diff"}, \code{"br_ref"}, \code{"ntb"},
#'   \code{"ntb_lower"}, \code{"wr"} and \code{"wo"}.
#' @param threshold Numeric vector of thresholds; one row of the output per
#'   value.
#' @param admissibility Logical: use the admissibility of the benefit-risk
#'   scores (\code{"br_diff"} and \code{"br_ref"} only).
#' @return A data frame with columns \code{statistic}, \code{threshold},
#'   \code{p_treatment}, \code{p_control} and \code{p_none}.
#' @examples
#' res <- data.frame(br_diff = c(0.2, -0.1, 0.05, 0.3), adm_trt = c(TRUE, TRUE, FALSE, TRUE),
#'                   adm_ctl = c(TRUE, TRUE, TRUE, FALSE), ntb = c(0.1, -0.2, 0.05, 0.3),
#'                   wr = c(1.3, 0.6, 1.1, 2))
#' SelectionOC(res, "br_diff", threshold = c(0, 0.1))
#' SelectionOC(res, "wr")
#' @seealso \code{\link{SimSelection}}, \code{\link{CalibrateThreshold}}
#' @export
SelectionOC <- function(results, statistic = c("br_diff", "br_ref", "ntb", "ntb_lower",
                                               "wr", "wo"),
                        threshold = NULL, admissibility = TRUE) {
  if (!is.data.frame(results)) stop("'results' must be a data frame.", call. = FALSE)
  statistic <- match.arg(statistic)
  if (is.null(threshold)) {
    if (statistic == "br_ref") {
      stop("'threshold' is required for 'statistic' = \"br_ref\".", call. = FALSE)
    }
    threshold <- if (statistic %in% c("wr", "wo")) 1 else 0
  }
  if (!is.numeric(threshold) || length(threshold) == 0L || anyNA(threshold)) {
    stop("'threshold' must be a numeric vector without missing values.", call. = FALSE)
  }
  if (!is.logical(admissibility) || length(admissibility) != 1L || is.na(admissibility)) {
    stop("'admissibility' must be TRUE or FALSE.", call. = FALSE)
  }
  out <- do.call(rbind, lapply(threshold, function(th) {
    sel <- .rule_select(results, statistic, th, admissibility)
    data.frame(statistic = statistic, threshold = th,
               p_treatment = mean(sel == "treatment"), p_control = mean(sel == "control"),
               p_none = mean(sel == "none"), stringsAsFactors = FALSE)
  }))
  rownames(out) <- NULL
  out
}
