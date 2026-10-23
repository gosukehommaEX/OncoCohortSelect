#' Default title of the plot of selection probabilities (internal)
#'
#' @param statistic Name of the statistic of the decision rule.
#' @param thr Numeric vector of the thresholds of the plot.
#' @return Character scalar: the short name of the statistic and, for a single
#'   threshold, the threshold in parentheses on a second line, so that the
#'   title fits above a narrow plot.
#' @keywords internal
#' @noRd
.oc_title <- function(statistic, thr) {
  main <- .stat_label(statistic, short = TRUE)
  if (length(thr) == 1L) main <- paste0(main, "\n(threshold ", .fmt_num(thr, 4), ")")
  main
}
