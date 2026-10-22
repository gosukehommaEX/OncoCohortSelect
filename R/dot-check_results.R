#' Check simulation results (internal)
#'
#' @param results Data frame returned by \code{\link{SimSelection}}.
#' @param statistic Name of the statistic of a decision rule.
#' @return \code{NULL}, invisibly; an error if \code{results} does not have the
#'   columns \code{sim}, \code{group}, \code{is_reference} and
#'   \code{statistic}, or does not have exactly one reference cohort in each
#'   simulated trial.
#' @keywords internal
#' @noRd
.check_results <- function(results, statistic) {
  if (!is.data.frame(results) || nrow(results) == 0L) {
    stop("'results' must be a data frame with at least one row.", call. = FALSE)
  }
  miss <- setdiff(c("sim", "group", "is_reference", statistic), names(results))
  if (length(miss)) {
    stop("'results' has no column ", paste(miss, collapse = ", "),
         "; use the output of SimSelection().", call. = FALSE)
  }
  ref <- results$is_reference
  if (!is.logical(ref) || anyNA(ref) || anyNA(results$sim)) {
    stop("The columns 'sim' and 'is_reference' of 'results' must not contain ",
         "missing values, and 'is_reference' must be logical.", call. = FALSE)
  }
  if (any(tapply(ref, as.character(results$sim), sum) != 1L)) {
    stop("Each simulated trial in 'results' must have exactly one reference cohort.",
         call. = FALSE)
  }
  invisible(NULL)
}
