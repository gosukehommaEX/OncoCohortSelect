#' Expand an argument to one value per cohort (internal)
#'
#' @param x \code{NULL}, a vector used for every cohort, or a list with one
#'   element per cohort.
#' @param k Number of cohorts.
#' @param name Name of the argument, for error messages.
#' @return A list of length \code{k}.
#' @keywords internal
#' @noRd
.per_cohort <- function(x, k, name) {
  if (is.null(x)) return(vector("list", k))
  if (is.list(x)) {
    if (length(x) != k) {
      stop("'", name, "' given as a list must have one element per cohort.", call. = FALSE)
    }
    return(x)
  }
  rep(list(x), k)
}
