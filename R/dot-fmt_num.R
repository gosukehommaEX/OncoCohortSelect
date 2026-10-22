#' Format numbers without padding (internal)
#'
#' \code{formatC()} pads its result to a common field width; the blanks are
#' removed here so that numbers can be pasted into text.
#'
#' @param x Numeric vector.
#' @param digits Number of significant digits (\code{format = "g"}) or of
#'   decimals (\code{format = "f"}).
#' @param format \code{"g"} or \code{"f"}, as in \code{formatC()}.
#' @return Character vector.
#' @keywords internal
#' @noRd
.fmt_num <- function(x, digits, format = "g") {
  trimws(formatC(x, digits = digits, format = format))
}
