#' Evaluate a Kaplan-Meier estimate (internal)
#'
#' @param km List returned by \code{.km()}.
#' @param t Numeric vector or matrix of times.
#' @param left If \code{TRUE}, the left limit \code{P(T >= t)}; otherwise
#'   \code{P(T > t)}.
#' @param beyond Value after the largest observed time, where the estimate is
#'   not defined: \code{"na"}, \code{"last"} (the survival at the largest
#'   observed time) or \code{"zero"}.
#' @return Survival probabilities with the dimensions of \code{t}.
#' @keywords internal
#' @noRd
.km_eval <- function(km, t, left = FALSE, beyond = c("na", "last", "zero")) {
  beyond <- match.arg(beyond)
  s <- c(1, km$surv)[findInterval(t, km$time, left.open = left) + 1L]
  out <- t > km$tmax
  s[out] <- switch(beyond, na = NA_real_, last = km$last, zero = 0)
  dim(s) <- dim(t)
  s
}
