#' Generalized pairwise comparison of prioritized endpoints (internal)
#'
#' Each pair of a treatment patient and a control patient is compared on the
#' endpoints in priority order; the first endpoint that decides the pair
#' determines a win or a loss, and a pair that no endpoint decides is a tie.
#'
#' @param xt,xc Data frames of the treatment and control patients.
#' @param eps List of \code{Endpoint} objects in priority order.
#' @param threshold Numeric vector of thresholds, one per element of
#'   \code{eps}.
#' @return A list with the logical matrices \code{win} and \code{loss} (one
#'   row per treatment patient, one column per control patient) and the
#'   numbers of pairs won (\code{win.k}) and lost (\code{loss.k}) at each
#'   priority level.
#' @keywords internal
#' @noRd
.gpc_pairs <- function(xt, xc, eps, threshold) {
  m <- nrow(xt)
  n <- nrow(xc)
  K <- length(eps)
  open <- matrix(TRUE, m, n)
  win <- matrix(FALSE, m, n)
  loss <- matrix(FALSE, m, n)
  win_k <- numeric(K)
  loss_k <- numeric(K)
  for (k in seq_len(K)) {
    sc <- .gpc_score(xt, xc, eps[[k]], threshold[k])
    wk <- open & sc$win
    lk <- open & sc$loss
    win <- win | wk
    loss <- loss | lk
    open <- open & !wk & !lk
    win_k[k] <- sum(wk)
    loss_k[k] <- sum(lk)
  }
  list(win = win, loss = loss, win.k = win_k, loss.k = loss_k)
}
