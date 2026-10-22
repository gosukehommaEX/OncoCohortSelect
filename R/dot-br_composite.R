#' Composite benefit-risk score and admissibility (internal)
#'
#' @param S Matrix of component scores (one row per group, one column per
#'   component).
#' @param crit Criteria returned by \code{.check_criteria()}.
#' @return A list with \code{BR}, the weighted geometric score
#'   \code{prod(S ^ weight)} of each row, and \code{admissible}, \code{TRUE}
#'   when every component with a cutoff has a score of at least its cutoff.
#' @keywords internal
#' @noRd
.br_composite <- function(S, crit) {
  w <- crit$weight
  use <- w > 0
  logS <- log(S[, use, drop = FALSE])
  br <- exp(rowSums(logS * rep(w[use], each = nrow(S))))
  cut <- crit$cutoff
  has <- !is.na(cut)
  adm <- if (any(has)) {
    rowSums(S[, has, drop = FALSE] >= rep(cut[has], each = nrow(S))) == sum(has)
  } else {
    rep(TRUE, nrow(S))
  }
  list(BR = unname(br), admissible = unname(adm))
}
