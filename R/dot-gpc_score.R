#' Scores of all pairs on one endpoint (internal)
#'
#' Compares every treatment patient (rows) with every control patient
#' (columns) on one endpoint. A binary endpoint gives a win when the treatment
#' patient has the favorable value and the control patient does not, and a
#' loss in the opposite case; a pair with a missing value is undecided.
#'
#' A time-to-event endpoint is scored by the rule of Gehan: the true time of
#' one patient is known to exceed that of the other by at least
#' \code{threshold} when the other patient has an event and the observed time
#' of the first patient exceeds it by at least \code{threshold}. With
#' \code{threshold = 0} the true time must be strictly longer, and a censored
#' time equal to an event time counts as longer, since the censored patient
#' was event-free at that time. Other pairs are undecided.
#'
#' @param xt,xc Data frames of the treatment and control patients.
#' @param endpoint An \code{Endpoint} object.
#' @param threshold Non-negative threshold (time-to-event endpoints).
#' @return A list of two logical matrices with one row per treatment patient
#'   and one column per control patient: \code{win} and \code{loss} of the
#'   treatment patient.
#' @keywords internal
#' @noRd
.gpc_score <- function(xt, xc, endpoint, threshold = 0) {
  m <- nrow(xt)
  n <- nrow(xc)
  v1 <- .ep_values(xt, endpoint)
  v0 <- .ep_values(xc, endpoint)
  if (endpoint$type == "binary") {
    y1 <- v1$value
    y0 <- v0$value
    if (!endpoint$higher.better) {
      y1 <- 1 - y1
      y0 <- 1 - y0
    }
    win <- outer(y1 %in% 1, y0 %in% 0, "&")
    loss <- outer(y1 %in% 0, y0 %in% 1, "&")
  } else {
    e1 <- matrix(v1$event == 1, m, n)
    e0 <- matrix(v0$event == 1, m, n, byrow = TRUE)
    d <- outer(v1$time, v0$time, "-")
    if (threshold > 0) {
      up <- d >= threshold
      down <- d <= -threshold
    } else {
      up <- d > 0
      down <- d < 0
    }
    # treatment known to be longer: the control patient has an event
    t_longer <- e0 & up
    # control known to be longer: the treatment patient has an event
    c_longer <- e1 & down
    if (threshold == 0) {
      tie <- d == 0
      t_longer <- t_longer | (tie & e0 & !e1)
      c_longer <- c_longer | (tie & e1 & !e0)
    }
    if (endpoint$higher.better) {
      win <- t_longer
      loss <- c_longer
    } else {
      win <- c_longer
      loss <- t_longer
    }
  }
  list(win = win, loss = loss)
}
