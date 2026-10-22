#' Selection probabilities of a decision rule
#'
#' @description
#' Computes, from the results of \code{\link{SimSelection}}, the proportion of
#' simulated trials in which a decision rule selects each cohort.
#'
#' @details
#' In each simulated trial, the cohorts other than the reference cohort whose
#' \code{statistic} exceeds \code{threshold} are candidates, and the candidate
#' with the largest statistic is selected; without a candidate, the reference
#' cohort is selected. A cohort with a missing statistic (for example a win
#' ratio when no pair is decided) is not a candidate. The statistics are
#' \itemize{
#'   \item \code{"br_diff"}: the difference of the benefit-risk scores against
#'     target values from that of the reference cohort. With
#'     \code{admissibility = TRUE}, a candidate must be admissible; when the
#'     reference cohort is not admissible, every admissible cohort is a
#'     candidate whatever the threshold, and no cohort is selected when none
#'     is admissible.
#'   \item \code{"br_ref"}: the benefit-risk score relative to the reference
#'     cohort. With \code{admissibility = TRUE}, a candidate must also be
#'     admissible relative to the reference cohort.
#'   \item \code{"ntb"}, \code{"ntb_lower"}, \code{"wr"}, \code{"wo"}: the net
#'     treatment benefit against the reference cohort, its lower confidence
#'     bound, the win ratio and the win odds.
#' }
#' The default thresholds are 0 for the differences and the net treatment
#' benefit and 1 for the win ratio and the win odds; \code{"br_ref"} has no
#' default.
#'
#' @param results Data frame returned by \code{\link{SimSelection}}.
#' @param statistic One of \code{"br_diff"}, \code{"br_ref"}, \code{"ntb"},
#'   \code{"ntb_lower"}, \code{"wr"} and \code{"wo"}.
#' @param threshold Numeric vector of thresholds.
#' @param admissibility Logical: use the admissibility of the benefit-risk
#'   scores (\code{"br_diff"} and \code{"br_ref"} only).
#' @return A data frame of class \code{SelectionOC} with columns
#'   \code{statistic}, \code{threshold}, \code{group} and \code{p_select},
#'   with one row per threshold and cohort (in the order of \code{results}),
#'   and, for \code{"br_diff"} with admissibility, a row \code{"(none)"} for
#'   the trials in which no cohort is selected. See
#'   \code{\link{SelectionOC-methods}} for \code{print()} and \code{plot()}.
#' @examples
#' res <- data.frame(sim = rep(1:4, each = 3),
#'                   group = rep(c("A", "B", "C"), 4),
#'                   is_reference = rep(c(TRUE, FALSE, FALSE), 4),
#'                   br_diff = c(NA, 0.2, 0.1, NA, -0.1, 0.05, NA, 0.3, 0.4, NA, 0, -0.2),
#'                   adm = c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE, FALSE,
#'                           FALSE, FALSE, FALSE),
#'                   ntb = c(NA, 0.1, -0.1, NA, -0.2, 0.05, NA, 0.3, 0.1, NA, 0.02, 0.01))
#' SelectionOC(res, "br_diff", threshold = c(0, 0.1))
#' SelectionOC(res, "ntb")
#' @seealso \code{\link{SimSelection}}, \code{\link{CalibrateThreshold}}
#' @export
SelectionOC <- function(results, statistic = c("br_diff", "br_ref", "ntb", "ntb_lower",
                                               "wr", "wo"),
                        threshold = NULL, admissibility = TRUE) {
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
  .check_results(results, statistic)
  lev <- unique(as.character(results$group))
  if (admissibility && statistic == "br_diff") lev <- c(lev, "(none)")
  out <- do.call(rbind, lapply(threshold, function(th) {
    sel <- .rule_select(results, statistic, th, admissibility)$selected
    sel[is.na(sel)] <- "(none)"
    data.frame(statistic = statistic, threshold = th, group = lev,
               p_select = unname(vapply(lev, function(l) mean(sel == l), numeric(1))),
               stringsAsFactors = FALSE)
  }))
  rownames(out) <- NULL
  class(out) <- c("SelectionOC", "data.frame")
  out
}
