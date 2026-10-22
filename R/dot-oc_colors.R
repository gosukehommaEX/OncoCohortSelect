#' Colors of the plots (internal)
#'
#' @param n Number of colors.
#' @return Character vector of \code{n} colors from the Okabe-Ito palette,
#'   which is readable with color vision deficiencies, recycled when \code{n}
#'   is larger than 8.
#' @keywords internal
#' @noRd
.oc_colors <- function(n) {
  pal <- unname(grDevices::palette.colors(9, "Okabe-Ito"))[c(6, 7, 3, 4, 8, 2, 5, 1)]
  rep_len(pal, n)
}
