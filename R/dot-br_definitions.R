#' Definitions of the components of a benefit-risk score (internal)
#'
#' @param crit Criteria returned by \code{.check_criteria()}.
#' @param reference Logical: whether the components are relative to a
#'   reference cohort.
#' @return Character vector with the definition of each component, for
#'   example \code{"P(rate >= 0.3)"} or \code{"P(HR <= 0.8)"}.
#' @keywords internal
#' @noRd
.br_definitions <- function(crit, reference) {
  num <- function(v) .fmt_num(v, 4)
  hb <- crit$higher.better
  ge <- ifelse(hb, ">=", "<=")
  param <- ifelse(crit$measure == "rate", "rate", paste0("S(", num(crit$time), ")"))
  if (!reference) {
    return(paste0("P(", param, " ", ge, " ", num(crit$target), ")"))
  }
  ref_param <- ifelse(crit$measure == "rate", "reference rate",
                      paste0("reference S(", num(crit$time), ")"))
  out <- paste0("P(", param, " - ", ref_param, " ", ge, " ", num(crit$target), ")")
  hr <- crit$measure == "hr"
  out[hr] <- paste0("P(HR ", ifelse(hb[hr], "<=", ">="), " ", num(crit$target[hr]), ")")
  out
}
