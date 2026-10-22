#' Description of a statistic of SimSelection() (internal)
#'
#' @param statistic Name of a column of the output of \code{SimSelection()}.
#' @return A short description, or \code{statistic} itself when it is not
#'   one of the known statistics.
#' @keywords internal
#' @noRd
.stat_label <- function(statistic) {
  lab <- c(br = "Benefit-risk score against target values",
           br_diff = "Difference of the benefit-risk scores from the reference",
           br_ref = "Benefit-risk score relative to the reference",
           ntb = "Net treatment benefit against the reference",
           ntb_lower = "Lower confidence bound of the net treatment benefit",
           wr = "Win ratio against the reference",
           wo = "Win odds against the reference")
  if (statistic %in% names(lab)) unname(lab[statistic]) else statistic
}
