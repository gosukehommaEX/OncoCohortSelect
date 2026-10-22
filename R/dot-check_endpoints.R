#' Check endpoint definitions and their columns (internal)
#'
#' @param endpoints An \code{Endpoint} object or a list of them.
#' @param data Optional data frame whose columns are checked.
#' @return A named list of \code{Endpoint} objects (names are the endpoint
#'   names).
#' @keywords internal
#' @noRd
.check_endpoints <- function(endpoints, data = NULL) {
  if (inherits(endpoints, "Endpoint")) endpoints <- list(endpoints)
  if (!is.list(endpoints) || length(endpoints) == 0L ||
      !all(vapply(endpoints, inherits, logical(1), what = "Endpoint"))) {
    stop("'endpoints' must be an Endpoint object or a list of them.", call. = FALSE)
  }
  nm <- vapply(endpoints, function(e) e$name, character(1))
  if (anyDuplicated(nm)) stop("The endpoint names must be unique.", call. = FALSE)
  names(endpoints) <- nm
  if (!is.null(data)) {
    for (e in endpoints) {
      cols <- if (e$type == "binary") e$var else c(e$time, e$event, e$censor)
      miss <- setdiff(cols, names(data))
      if (length(miss)) {
        stop("Column(s) ", paste(miss, collapse = ", "), " of endpoint '", e$name,
             "' not found in 'data'.", call. = FALSE)
      }
      if (e$type == "binary") {
        x <- data[[e$var]]
        if (is.null(e$positive)) {
          if (!(is.numeric(x) || is.logical(x)) || any(!is.na(x) & !(x %in% c(0, 1)))) {
            stop("Column '", e$var, "' must contain only 0, 1 or NA ",
                 "(or give 'positive' in Endpoint()).", call. = FALSE)
          }
        } else if (!is.atomic(x) && !is.factor(x)) {
          stop("Column '", e$var, "' must be a vector.", call. = FALSE)
        }
      } else {
        tt <- data[[e$time]]
        if (!is.numeric(tt) || anyNA(tt) || any(!is.finite(tt)) || any(tt < 0)) {
          stop("Column '", e$time, "' must contain non-negative finite times.", call. = FALSE)
        }
        if (is.null(e$censor)) {
          ev <- data[[e$event]]
          if (!(is.numeric(ev) || is.logical(ev)) || anyNA(ev) || any(!(ev %in% c(0, 1)))) {
            stop("Column '", e$event, "' must contain only 0 and 1.", call. = FALSE)
          }
        } else {
          cn <- data[[e$censor]]
          if (!(is.numeric(cn) || is.logical(cn)) || anyNA(cn)) {
            stop("Column '", e$censor, "' must contain numeric censoring indicators ",
                 "without missing values.", call. = FALSE)
          }
        }
      }
    }
  }
  endpoints
}
