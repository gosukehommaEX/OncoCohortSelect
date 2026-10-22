#' Selection probabilities as a matrix (internal)
#'
#' @param x Data frame returned by \code{SelectionOC()}.
#' @return A matrix with one row per threshold (named by the threshold) and
#'   one column per cohort (in the order of \code{x}).
#' @keywords internal
#' @noRd
.oc_matrix <- function(x) {
  thr <- unique(x$threshold)
  grp <- unique(as.character(x$group))
  M <- matrix(NA_real_, length(thr), length(grp),
              dimnames = list(as.character(thr), grp))
  M[cbind(match(x$threshold, thr), match(as.character(x$group), grp))] <- x$p_select
  M
}
