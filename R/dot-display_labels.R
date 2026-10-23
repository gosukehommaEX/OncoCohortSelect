#' Labels of the components of a benefit-risk score for display (internal)
#'
#' The default labels of the components are syntactic names such as
#' \code{PFS_S6} and \code{OS_HR}; they are shown as \code{PFS S(6)} and
#' \code{OS HR}. Other labels are shown with their underscores replaced by
#' spaces.
#'
#' @param comp Data frame with the columns \code{label}, \code{endpoint} and
#'   \code{definition}, the attribute \code{components} of the output of
#'   \code{BenefitRisk()}.
#' @return Character vector of the labels shown.
#' @keywords internal
#' @noRd
.display_labels <- function(comp) {
  lab <- as.character(comp$label)
  ep <- as.character(comp$endpoint)
  def <- as.character(comp$definition)
  # time of a survival probability, as written in the definition: P(S(6) ...
  surv <- grepl("^P\\(S\\(", def)
  time <- ifelse(surv, sub("^P\\(S\\(([^)]*)\\).*$", "\\1", def), NA_character_)
  is_surv <- surv & lab == paste0(ep, "_S", time)
  is_hr <- lab == paste0(ep, "_HR")
  out <- gsub("_", " ", lab, fixed = TRUE)
  out[is_surv] <- paste0(ep[is_surv], " S(", time[is_surv], ")")
  out[is_hr] <- paste0(ep[is_hr], " HR")
  out
}
