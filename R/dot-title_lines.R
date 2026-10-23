#' Number of lines of a title (internal)
#'
#' @param main Character scalar, possibly with line breaks.
#' @return Integer scalar, at least 1.
#' @keywords internal
#' @noRd
.title_lines <- function(main) {
  if (!is.character(main) || length(main) != 1L || is.na(main)) return(1L)
  max(1L, length(strsplit(main, "\n", fixed = TRUE)[[1]]))
}
