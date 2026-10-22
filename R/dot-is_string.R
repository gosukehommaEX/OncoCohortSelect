#' Check for a single non-empty character string (internal)
#'
#' @param x Object to check.
#' @return \code{TRUE} if \code{x} is a character vector of length 1 that is
#'   neither \code{NA} nor empty, otherwise \code{FALSE}.
#' @keywords internal
#' @noRd
.is_string <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
}
