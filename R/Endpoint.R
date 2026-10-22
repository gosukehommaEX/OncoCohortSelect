#' Define an endpoint
#'
#' @description
#' Defines a binary or time-to-event endpoint by the columns of a patient-level
#' data frame that hold it and by the direction in which it is favorable. The
#' definitions are used by \code{\link{BenefitRisk}}, \code{\link{WinStat}} and
#' \code{\link{SimSelection}}; any number of endpoints can be defined.
#'
#' @details
#' A binary endpoint is a column with values 0, 1 or \code{NA}, for example the
#' objective response (\code{higher.better = TRUE}) or the occurrence of an
#' adverse event (\code{higher.better = FALSE}). Missing values are excluded
#' from the posterior distribution in \code{\link{BenefitRisk}} and make a pair
#' uninformative for this endpoint in \code{\link{WinStat}}.
#'
#' A time-to-event endpoint is given by a column of observed times and a column
#' of event indicators (1 for an event, 0 for censoring), for example overall
#' survival or progression-free survival. With \code{higher.better = TRUE}
#' (the usual case) longer times are favorable.
#'
#' @param name Name of the endpoint, used to refer to it in the criteria of
#'   \code{\link{BenefitRisk}} and in the priority order of
#'   \code{\link{WinStat}}.
#' @param type \code{"binary"} or \code{"tte"} (time to event).
#' @param var For a binary endpoint, the name of the column with the values.
#' @param time,event For a time-to-event endpoint, the names of the columns
#'   with the observed times and the event indicators.
#' @param higher.better Logical: \code{TRUE} if a value of 1 (binary) or a
#'   longer time (time to event) is favorable.
#' @return An object of class \code{Endpoint}: a list with elements
#'   \code{name}, \code{type}, \code{var}, \code{time}, \code{event} and
#'   \code{higher.better}.
#' @examples
#' eps <- list(
#'   Endpoint("OS", "tte", time = "os_tte", event = "os_event"),
#'   Endpoint("PFS", "tte", time = "pfs_tte", event = "pfs_event"),
#'   Endpoint("ORR", "binary", var = "response"),
#'   Endpoint("AE", "binary", var = "ae", higher.better = FALSE)
#' )
#' eps[[4]]$higher.better
#' @seealso \code{\link{BenefitRisk}}, \code{\link{WinStat}}
#' @export
Endpoint <- function(name, type = c("binary", "tte"), var = NULL, time = NULL,
                     event = NULL, higher.better = TRUE) {
  if (!.is_string(name)) {
    stop("'name' must be a single non-empty character string.", call. = FALSE)
  }
  type <- match.arg(type)
  if (type == "binary") {
    if (!.is_string(var)) {
      stop("'var' must be the name of the column of a binary endpoint.", call. = FALSE)
    }
    if (!is.null(time) || !is.null(event)) {
      stop("'time' and 'event' are used only for time-to-event endpoints.", call. = FALSE)
    }
  } else {
    if (!.is_string(time) || !.is_string(event)) {
      stop("'time' and 'event' must be the names of the columns of a time-to-event endpoint.",
           call. = FALSE)
    }
    if (!is.null(var)) {
      stop("'var' is used only for binary endpoints.", call. = FALSE)
    }
  }
  if (!is.logical(higher.better) || length(higher.better) != 1L || is.na(higher.better)) {
    stop("'higher.better' must be TRUE or FALSE.", call. = FALSE)
  }
  structure(list(name = name, type = type, var = var, time = time, event = event,
                 higher.better = higher.better),
            class = "Endpoint")
}
