#' Values of an endpoint in standard coding (internal)
#'
#' @param data Data frame.
#' @param endpoint An \code{Endpoint} object.
#' @return For a binary endpoint, a list with \code{value}: numeric 1, 0 or
#'   \code{NA} (values in \code{positive} count as 1 when it is given). For a
#'   time-to-event endpoint, a list with numeric \code{time} and \code{event}
#'   (1 = event, 0 = censored; from \code{censor} when it is given).
#' @keywords internal
#' @noRd
.ep_values <- function(data, endpoint) {
  if (endpoint$type == "binary") {
    x <- data[[endpoint$var]]
    value <- if (is.null(endpoint$positive)) {
      as.numeric(x)
    } else {
      ifelse(is.na(x), NA_real_, as.numeric(x %in% endpoint$positive))
    }
    list(value = value)
  } else {
    event <- if (is.null(endpoint$censor)) {
      as.numeric(data[[endpoint$event]])
    } else {
      as.numeric(data[[endpoint$censor]] == 0)
    }
    list(time = as.numeric(data[[endpoint$time]]), event = event)
  }
}
