#' Print a data frame without its subclass (internal)
#'
#' @param x Data frame, possibly with a subclass and extra attributes.
#' @param digits Minimal number of significant digits of numeric columns.
#' @param n Maximal number of rows printed, or \code{NULL} for all rows.
#' @return \code{x}, invisibly.
#' @keywords internal
#' @noRd
.print_df <- function(x, digits = 3, n = NULL) {
  y <- x
  class(y) <- "data.frame"
  N <- nrow(y)
  if (!is.null(n) && N > n) {
    print(y[seq_len(n), , drop = FALSE], digits = digits, row.names = FALSE)
    cat("# ... with ", N - n, " more row", if (N - n > 1L) "s", "\n", sep = "")
  } else {
    print(y, digits = digits, row.names = FALSE)
  }
  invisible(x)
}
