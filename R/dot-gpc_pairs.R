#' Generalized pairwise comparison of prioritized endpoints (internal)
#'
#' Each pair of a treatment patient and a control patient is compared on the
#' endpoints in priority order. With the Gehan scoring rule, the first
#' endpoint that decides the pair determines a win or a loss, and a pair that
#' no endpoint decides is a tie. With the Peron scoring rule, a pair is won or
#' lost on an endpoint with a probability, and the rest of its weight goes to
#' the next endpoints.
#'
#' The weight of a pair at a priority level is the product, over the other
#' endpoints already used, of the probability that the pair was undecided at
#' the last threshold of that endpoint. When an endpoint is used again with a
#' smaller threshold, the probabilities of a win and a loss at its previous
#' threshold are subtracted, since a pair won at the larger threshold is also
#' won at the smaller one (the rule of the \code{BuyseTest} package). With
#' scores of 0 and 1 (Gehan) this reduces to passing the undecided pairs to the
#' next level.
#'
#' @param xt,xc Data frames of the treatment and control patients.
#' @param eps List of \code{Endpoint} objects in priority order.
#' @param threshold Numeric vector of thresholds, one per element of
#'   \code{eps}.
#' @param scoring \code{"gehan"} or \code{"peron"}.
#' @return A list with the numeric matrices \code{win} and \code{loss} (one
#'   row per treatment patient, one column per control patient; the
#'   probabilities that the treatment patient wins and loses the pair) and the
#'   sums of these probabilities over the pairs won (\code{win.k}) and lost
#'   (\code{loss.k}) at each priority level.
#' @keywords internal
#' @noRd
.gpc_pairs <- function(xt, xc, eps, threshold, scoring = c("gehan", "peron")) {
  scoring <- match.arg(scoring)
  m <- nrow(xt)
  n <- nrow(xc)
  K <- length(eps)
  win <- matrix(0, m, n)
  loss <- matrix(0, m, n)
  win_k <- numeric(K)
  loss_k <- numeric(K)
  # for each endpoint already used: probability that the pair is undecided,
  # won and lost at its last threshold
  rest <- list()
  won <- list()
  lost <- list()
  for (k in seq_len(K)) {
    nm <- eps[[k]]$name
    sc <- if (scoring == "peron") {
      .gpc_score_peron(xt, xc, eps[[k]], threshold[k])
    } else {
      .gpc_score(xt, xc, eps[[k]], threshold[k])
    }
    f <- sc$win * 1
    u <- sc$loss * 1
    w <- matrix(1, m, n)
    for (o in setdiff(names(rest), nm)) w <- w * rest[[o]]
    if (nm %in% names(rest)) {
      wk <- w * (f - won[[nm]])
      lk <- w * (u - lost[[nm]])
    } else {
      wk <- w * f
      lk <- w * u
    }
    win <- win + wk
    loss <- loss + lk
    win_k[k] <- sum(wk)
    loss_k[k] <- sum(lk)
    rest[[nm]] <- pmax(1 - f - u, 0)
    won[[nm]] <- f
    lost[[nm]] <- u
  }
  list(win = win, loss = loss, win.k = win_k, loss.k = loss_k)
}
