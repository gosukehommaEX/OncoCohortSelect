#' Sums by an integer key (internal)
#'
#' @param x Numeric vector.
#' @param key Integer vector of the same length as \code{x} with values in
#'   \code{1, ..., nkey}.
#' @param nkey Number of keys.
#' @return Numeric vector of length \code{nkey}: the sum of \code{x} for each
#'   key, 0 for keys without elements.
#' @keywords internal
#' @noRd
.sum_by <- function(x, key, nkey) {
  out <- numeric(nkey)
  if (length(x) == 0L) return(out)
  r <- rowsum(as.numeric(x), key)
  out[as.integer(rownames(r))] <- r[, 1L]
  out
}
