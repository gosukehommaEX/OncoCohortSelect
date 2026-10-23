#' Default title of the plot of win statistics (internal)
#'
#' @param x List returned by \code{WinStat()}.
#' @return Character scalar: the net treatment benefit on the first line and
#'   the win ratio on the second, each with its confidence interval in
#'   parentheses when it is available.
#' @keywords internal
#' @noRd
.winstat_title <- function(x) {
  f2 <- function(v) .fmt_num(v, 2, "f")
  part <- function(i, name) {
    r <- x$ci[i, ]
    out <- paste(name, f2(r$estimate))
    if (!is.na(r$lower) && !is.na(r$upper)) {
      lvl <- if (is.null(x$settings)) "" else
        paste0(round(100 * x$settings$conf.level, 1), "% ")
      out <- paste0(out, " (", lvl, "CI ", f2(r$lower), " to ", f2(r$upper), ")")
    }
    out
  }
  paste0(part(1L, "NTB"), "\n", part(2L, "WR"))
}
