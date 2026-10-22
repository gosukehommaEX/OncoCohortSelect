#' Kaplan-Meier estimate (internal)
#'
#' @param time Numeric vector of observed times.
#' @param event Numeric or logical vector of event indicators (1 = event).
#' @return A list with \code{time} (distinct event times in increasing order),
#'   \code{surv} (survival just after each event time), \code{tmax} (largest
#'   observed time) and \code{last} (survival at \code{tmax}).
#' @keywords internal
#' @noRd
.km <- function(time, event) {
  ev <- event == 1
  ut <- sort(unique(time[ev]))
  if (length(ut)) {
    d <- tabulate(match(time[ev], ut), length(ut))
    # number at risk: patients with an observed time of at least t
    at_risk <- length(time) - findInterval(ut, sort(time), left.open = TRUE)
    surv <- cumprod(1 - d / at_risk)
  } else {
    surv <- numeric(0)
  }
  list(time = ut, surv = surv, tmax = max(time),
       last = if (length(surv)) surv[length(surv)] else 1)
}
