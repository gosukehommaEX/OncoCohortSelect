#' Cohort selected in each simulated trial (internal)
#'
#' In each simulated trial, the cohorts other than the reference whose
#' statistic exceeds the threshold are candidates, and the candidate with the
#' largest statistic is selected (the first in the order of \code{results} in
#' case of ties); without a candidate the reference cohort is selected. A
#' missing statistic does not make a candidate. For \code{"br_diff"} with
#' admissibility, a candidate must be admissible; with
#' \code{ref.inadmissible = "switch"}, when the reference cohort is not
#' admissible every admissible cohort is a candidate whatever the threshold,
#' and no cohort is selected when no cohort is admissible; with
#' \code{ref.inadmissible = "keep"}, a candidate must exceed the threshold
#' whatever the admissibility of the reference cohort. For \code{"br_ref"}
#' with admissibility, a candidate must be admissible relative to the
#' reference cohort.
#'
#' @param results Data frame returned by \code{\link{SimSelection}}.
#' @param statistic Name of the column used for the selection.
#' @param threshold Numeric threshold.
#' @param admissibility Logical: use the admissibility of the benefit-risk
#'   scores.
#' @param ref.inadmissible \code{"switch"} or \code{"keep"}: the rule of
#'   \code{"br_diff"} with admissibility when the reference cohort is not
#'   admissible.
#' @return A data frame with one row per simulated trial and the columns
#'   \code{sim}, \code{selected} (the selected cohort, \code{NA} when none is
#'   selected), \code{fixed} (a cohort other than the reference is selected
#'   whatever the threshold) and \code{max} (the largest statistic among the
#'   cohorts that are candidates when it exceeds the threshold, \code{-Inf}
#'   when there is none); \code{fixed} and \code{max} are used by
#'   \code{CalibrateThreshold()}.
#' @keywords internal
#' @noRd
.rule_select <- function(results, statistic, threshold, admissibility = TRUE,
                         ref.inadmissible = "switch") {
  .check_results(results, statistic)
  .check_adm(results, statistic, admissibility)
  s <- results[[statistic]]
  ref <- results$is_reference
  sim <- as.character(results$sim)
  group <- as.character(results$group)
  # cohorts that are candidates when the statistic exceeds the threshold, and
  # cohorts that are candidates whatever the threshold
  eligible <- !ref & !is.na(s)
  fixed <- rep(FALSE, nrow(results))
  ref_ok <- rep(TRUE, nrow(results))
  if (admissibility && statistic == "br_diff") {
    adm <- results$adm %in% TRUE
    if (identical(ref.inadmissible, "keep")) {
      eligible <- eligible & adm
    } else {
      ref_adm <- as.vector(tapply(adm & ref, sim, any)[sim])
      eligible <- eligible & adm & ref_adm
      fixed <- !ref & !is.na(s) & adm & !ref_adm
      ref_ok <- ref_adm
    }
  } else if (admissibility && statistic == "br_ref") {
    eligible <- eligible & results$adm_ref %in% TRUE
  }
  by_sim <- split(seq_len(nrow(results)), factor(sim, levels = unique(sim)))
  out <- lapply(by_sim, function(i) {
    cand <- i[fixed[i] | (eligible[i] & s[i] > threshold)]
    sel <- if (length(cand)) {
      cand[c(which.max(s[cand]), 1L)[1L]]
    } else if (ref_ok[i[1]]) {
      i[ref[i]]
    } else {
      NA_integer_
    }
    e <- i[eligible[i]]
    data.frame(sim = results$sim[i[1]], selected = group[sel],
               fixed = any(fixed[i]), max = if (length(e)) max(s[e]) else -Inf,
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, out)
  rownames(out) <- NULL
  out
}
