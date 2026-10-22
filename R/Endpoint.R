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
#' adverse event (\code{higher.better = FALSE}). With \code{positive}, the
#' column can hold any codes: the values in \code{positive} count as 1 and the
#' other values as 0, for example \code{positive = c("CR", "PR")} for a best
#' overall response or \code{positive = "Y"} for a flag that is \code{"Y"} or
#' blank. Missing values (\code{NA}) are excluded from the posterior
#' distribution in \code{\link{BenefitRisk}} and make a pair uninformative for
#' this endpoint in \code{\link{WinStat}}.
#'
#' A time-to-event endpoint is given by a column of observed times and either a
#' column of event indicators (\code{event}: 1 for an event, 0 for censoring)
#' or a column of censoring indicators (\code{censor}: 0 for an event, any
#' other value for censoring, as the variable \code{CNSR} of ADaM data sets),
#' for example overall survival or progression-free survival. With
#' \code{higher.better = TRUE} (the usual case) longer times are favorable.
#'
#' The columns are named freely, so that data with any variable names (for
#' example ADaM data sets restructured to one row per patient) can be analyzed,
#' and any number of endpoints can be defined.
#'
#' @param name Name of the endpoint, used to refer to it in the criteria of
#'   \code{\link{BenefitRisk}} and in the priority order of
#'   \code{\link{WinStat}}.
#' @param type \code{"binary"} or \code{"tte"} (time to event).
#' @param var For a binary endpoint, the name of the column with the values.
#' @param time For a time-to-event endpoint, the name of the column with the
#'   observed times.
#' @param event For a time-to-event endpoint, the name of the column with the
#'   event indicators (1 = event, 0 = censored). Give \code{event} or
#'   \code{censor}.
#' @param censor For a time-to-event endpoint, the name of the column with the
#'   censoring indicators (0 = event, other values = censored).
#' @param positive For a binary endpoint, optional vector of the values of
#'   \code{var} that count as 1; other non-missing values count as 0.
#' @param higher.better Logical: \code{TRUE} if a value of 1 (binary) or a
#'   longer time (time to event) is favorable.
#' @return An object of class \code{Endpoint}: a list with elements
#'   \code{name}, \code{type}, \code{var}, \code{time}, \code{event},
#'   \code{censor}, \code{positive} and \code{higher.better}.
#' @examples
#' eps <- list(
#'   Endpoint("OS", "tte", time = "os_tte", event = "os_event"),
#'   Endpoint("PFS", "tte", time = "pfs_tte", event = "pfs_event"),
#'   Endpoint("ORR", "binary", var = "response"),
#'   Endpoint("AE", "binary", var = "ae", higher.better = FALSE)
#' )
#' eps[[4]]$higher.better
#'
#' # variables in the style of ADaM data sets
#' adam_eps <- list(
#'   Endpoint("OS", "tte", time = "OSAVAL", censor = "OSCNSR"),
#'   Endpoint("ORR", "binary", var = "BOR", positive = c("CR", "PR")),
#'   Endpoint("AE", "binary", var = "AEFL", positive = "Y", higher.better = FALSE)
#' )
#' @seealso \code{\link{BenefitRisk}}, \code{\link{WinStat}}
#' @export
Endpoint <- function(name, type = c("binary", "tte"), var = NULL, time = NULL,
                     event = NULL, censor = NULL, positive = NULL,
                     higher.better = TRUE) {
  if (!.is_string(name)) {
    stop("'name' must be a single non-empty character string.", call. = FALSE)
  }
  type <- match.arg(type)
  if (type == "binary") {
    if (!.is_string(var)) {
      stop("'var' must be the name of the column of a binary endpoint.", call. = FALSE)
    }
    if (!is.null(time) || !is.null(event) || !is.null(censor)) {
      stop("'time', 'event' and 'censor' are used only for time-to-event endpoints.",
           call. = FALSE)
    }
    if (!is.null(positive) && (!is.atomic(positive) || length(positive) == 0L ||
                               anyNA(positive))) {
      stop("'positive' must be a vector of values without missing values.", call. = FALSE)
    }
  } else {
    if (!.is_string(time)) {
      stop("'time' must be the name of the column of the times of a time-to-event endpoint.",
           call. = FALSE)
    }
    if (is.null(event) == is.null(censor)) {
      stop("Give exactly one of 'event' and 'censor' for a time-to-event endpoint.",
           call. = FALSE)
    }
    if ((!is.null(event) && !.is_string(event)) || (!is.null(censor) && !.is_string(censor))) {
      stop("'event' or 'censor' must be the name of a column.", call. = FALSE)
    }
    if (!is.null(var) || !is.null(positive)) {
      stop("'var' and 'positive' are used only for binary endpoints.", call. = FALSE)
    }
  }
  if (!is.logical(higher.better) || length(higher.better) != 1L || is.na(higher.better)) {
    stop("'higher.better' must be TRUE or FALSE.", call. = FALSE)
  }
  structure(list(name = name, type = type, var = var, time = time, event = event,
                 censor = censor, positive = positive, higher.better = higher.better),
            class = "Endpoint")
}
