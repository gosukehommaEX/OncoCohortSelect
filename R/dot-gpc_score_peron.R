#' Scores of all pairs on one endpoint with the rule of Peron (internal)
#'
#' Compares every treatment patient (rows) with every control patient
#' (columns) on one endpoint. A binary endpoint is scored as in
#' \code{.gpc_score()}. For a time-to-event endpoint, the true time of a
#' censored patient is given the distribution of the Kaplan-Meier estimate of
#' its cohort conditional on survival beyond the censoring time, with point
#' masses at the later event times and a remaining mass beyond the largest
#' observed time of the cohort, where the estimate is not defined. The score
#' of the treatment patient is the probability that its true time is known to
#' be longer by at least \code{threshold} (strictly longer with
#' \code{threshold = 0}); the remaining mass counts only when the comparison
#' holds wherever the mass lies. The score of the control patient is defined
#' in the same way. The two scores are lower bounds and their sum can be less
#' than 1.
#'
#' @param xt,xc Data frames of the treatment and control patients.
#' @param endpoint An \code{Endpoint} object.
#' @param threshold Non-negative threshold (time-to-event endpoints).
#' @return A list of two numeric matrices with one row per treatment patient
#'   and one column per control patient: \code{win} and \code{loss}, the
#'   probabilities of a win and a loss of the treatment patient.
#' @keywords internal
#' @noRd
.gpc_score_peron <- function(xt, xc, endpoint, threshold = 0) {
  if (endpoint$type == "binary") {
    sc <- .gpc_score(xt, xc, endpoint, threshold)
    return(list(win = sc$win * 1, loss = sc$loss * 1))
  }
  v1 <- .ep_values(xt, endpoint)
  v0 <- .ep_values(xc, endpoint)
  x <- v1$time
  y <- v0$time
  m <- length(x)
  n <- length(y)
  tau <- threshold
  pos <- tau > 0
  k1 <- .km(x, v1$event)
  k0 <- .km(y, v0$event)
  X <- matrix(x, m, n)
  Y <- matrix(y, m, n, byrow = TRUE)
  # survival at the own observed time, the denominator for censored patients
  S1 <- matrix(.km_eval(k1, x), m, n)
  S0 <- matrix(.km_eval(k0, y), m, n, byrow = TRUE)
  d <- X - Y
  if (pos) {
    above <- d >= tau
    below <- d <= -tau
  } else {
    above <- d > 0
    below <- d < 0
  }
  # probability that the true time is shorter than the other time minus the
  # threshold is one minus the survival there (the last value is used after
  # the largest observed time); probability that it is longer than the other
  # time plus the threshold (0 after the largest observed time)
  c_sub <- .km_eval(k0, X - tau, left = !pos, beyond = "last")
  c_add <- .km_eval(k0, X + tau, left = pos, beyond = "zero")
  t_sub <- .km_eval(k1, Y - tau, left = !pos, beyond = "last")
  t_add <- .km_eval(k1, Y + tau, left = pos, beyond = "zero")
  e1 <- matrix(v1$event == 1, m, n)
  e0 <- matrix(v0$event == 1, m, n, byrow = TRUE)
  fav <- matrix(0, m, n)
  unf <- matrix(0, m, n)
  # both events
  i <- e1 & e0
  fav[i] <- above[i]
  unf[i] <- below[i]
  # treatment event, control censored
  i <- e1 & !e0
  fav[i] <- ifelse(above[i], 1 - c_sub[i] / S0[i], 0)
  unf[i] <- ifelse(below[i], 1, c_add[i] / S0[i])
  # treatment censored, control event
  i <- !e1 & e0
  fav[i] <- ifelse(above[i], 1, t_add[i] / S1[i])
  unf[i] <- ifelse(below[i], 1 - t_sub[i] / S1[i], 0)
  # both censored: sums over the jumps of one cohort after a start time of the
  # jump times the probability that the other true time is longer
  i <- !e1 & !e0
  if (any(i)) {
    b0 <- k0$time
    j0 <- -diff(c(1, k0$surv)) * .km_eval(k1, b0 + tau, left = pos, beyond = "zero")
    r0 <- c(rev(cumsum(rev(j0))), 0)
    b1 <- k1$time
    j1 <- -diff(c(1, k1$surv)) * .km_eval(k0, b1 + tau, left = pos, beyond = "zero")
    r1 <- c(rev(cumsum(rev(j1))), 0)
    c_right <- .km_eval(k0, X[i] - tau, beyond = "last")
    t_right <- .km_eval(k1, Y[i] - tau, beyond = "last")
    den <- S1[i] * S0[i]
    st <- ifelse(above[i], X[i] - tau, Y[i])
    fav[i] <- ifelse(above[i], 1 - c_right / S0[i], 0) + r0[findInterval(st, b0) + 1L] / den
    su <- ifelse(below[i], Y[i] - tau, X[i])
    unf[i] <- ifelse(below[i], 1 - t_right / S1[i], 0) + r1[findInterval(su, b1) + 1L] / den
  }
  # guard against rounding when a time minus or plus the threshold coincides
  # with another time
  fav[] <- pmin(pmax(fav, 0), 1)
  unf[] <- pmin(pmax(unf, 0), 1)
  if (endpoint$higher.better) {
    list(win = fav, loss = unf)
  } else {
    list(win = unf, loss = fav)
  }
}
