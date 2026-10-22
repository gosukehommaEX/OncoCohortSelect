#' Check the admissibility columns of simulation results (internal)
#'
#' @param results Data frame returned by \code{\link{SimSelection}}.
#' @param statistic Name of the statistic of the decision rule.
#' @param admissibility Logical: whether the admissibility is used.
#' @return \code{NULL}, invisibly; an error if the admissibility is used and
#'   its column (\code{adm} for \code{"br_diff"}, \code{adm_ref} for
#'   \code{"br_ref"}) is missing.
#' @keywords internal
#' @noRd
.check_adm <- function(results, statistic, admissibility) {
  need <- if (!admissibility) {
    character(0)
  } else if (statistic == "br_diff") {
    "adm"
  } else if (statistic == "br_ref") {
    "adm_ref"
  } else {
    character(0)
  }
  miss <- setdiff(need, names(results))
  if (length(miss)) {
    stop("'results' has no column ", miss,
         "; use admissibility = FALSE or the output of SimSelection().", call. = FALSE)
  }
  invisible(NULL)
}
