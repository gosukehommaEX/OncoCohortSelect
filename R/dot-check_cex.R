#' Check character expansion arguments (internal)
#'
#' @param ... Named arguments, each a positive number.
#' @return \code{NULL}, invisibly; an error for a value that is not a single
#'   positive number.
#' @keywords internal
#' @noRd
.check_cex <- function(...) {
  v <- list(...)
  for (nm in names(v)) {
    x <- v[[nm]]
    if (!is.numeric(x) || length(x) != 1L || is.na(x) || x <= 0) {
      stop("'", nm, "' must be a positive number.", call. = FALSE)
    }
  }
  invisible(NULL)
}
