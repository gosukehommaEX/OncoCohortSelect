#' Description of a statistic of SimSelection() (internal)
#'
#' @param statistic Name of a column of the output of \code{SimSelection()}.
#' @param short Logical: a short label without underscores, for example for an
#'   axis title, instead of a description.
#' @return A description or a short label, or \code{statistic} itself when it
#'   is not one of the known statistics.
#' @keywords internal
#' @noRd
.stat_label <- function(statistic, short = FALSE) {
  lab <- if (short) {
    c(br = "BR score",
      br_diff = "BR difference",
      br_ref = "BR relative to the reference",
      ntb = "Net treatment benefit",
      ntb_lower = "Lower confidence bound of the NTB",
      wr = "Win ratio",
      wo = "Win odds")
  } else {
    c(br = "Benefit-risk score against target values",
      br_diff = "Difference of the benefit-risk scores from the reference",
      br_ref = "Benefit-risk score relative to the reference",
      ntb = "Net treatment benefit against the reference",
      ntb_lower = "Lower confidence bound of the net treatment benefit",
      wr = "Win ratio against the reference",
      wo = "Win odds against the reference")
  }
  if (statistic %in% names(lab)) unname(lab[statistic]) else statistic
}
