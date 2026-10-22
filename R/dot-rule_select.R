#' Cohort selected in each simulated trial (internal)
#'
#' The treatment cohort is selected when the statistic exceeds the threshold.
#' For \code{"br_diff"} with admissibility, a cohort that is admissible is
#' selected over one that is not, the comparison of the scores applies when
#' both are admissible, and no cohort is selected when neither is. For
#' \code{"br_ref"} with admissibility, the treatment cohort must also be
#' admissible relative to the control cohort. A missing statistic selects the
#' control cohort.
#'
#' @param results Data frame returned by \code{\link{SimSelection}}.
#' @param statistic Name of the column used for the selection.
#' @param threshold Numeric threshold.
#' @param admissibility Logical: use the admissibility of the benefit-risk
#'   scores.
#' @return Character vector with \code{"treatment"}, \code{"control"} or
#'   \code{"none"} for each simulated trial.
#' @keywords internal
#' @noRd
.rule_select <- function(results, statistic, threshold, admissibility = TRUE) {
  s <- results[[statistic]]
  if (is.null(s)) {
    stop("'results' has no column '", statistic, "'.", call. = FALSE)
  }
  .check_adm(results, statistic, admissibility)
  out <- ifelse(!is.na(s) & s > threshold, "treatment", "control")
  if (admissibility && statistic == "br_diff") {
    at <- results$adm_trt %in% TRUE
    ac <- results$adm_ctl %in% TRUE
    out[at & !ac] <- "treatment"
    out[!at & ac] <- "control"
    out[!at & !ac] <- "none"
  } else if (admissibility && statistic == "br_ref") {
    out[!(results$adm_ref %in% TRUE)] <- "control"
  }
  out
}
