#' Sufficient statistics of an endpoint by group (internal)
#'
#' @param data Data frame.
#' @param endpoint An \code{Endpoint} object.
#' @param key Integer vector with the group (key) of each row of \code{data},
#'   in \code{1, ..., nkey}.
#' @param nkey Number of groups.
#' @return A list with numeric vectors of length \code{nkey}: \code{s1}, the
#'   number of patients with value 1 (binary) or the number of events (time to
#'   event), and \code{s2}, the number of patients with a non-missing value
#'   (binary) or the total follow-up time (time to event).
#' @keywords internal
#' @noRd
.suff_stats <- function(data, endpoint, key, nkey) {
  if (endpoint$type == "binary") {
    x <- as.numeric(data[[endpoint$var]])
    ok <- !is.na(x)
    list(s1 = .sum_by(ifelse(ok, x, 0), key, nkey),
         s2 = .sum_by(as.numeric(ok), key, nkey))
  } else {
    list(s1 = .sum_by(as.numeric(data[[endpoint$event]]), key, nkey),
         s2 = .sum_by(as.numeric(data[[endpoint$time]]), key, nkey))
  }
}
