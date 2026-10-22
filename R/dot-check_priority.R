#' Check the priority order and thresholds of pairwise comparisons (internal)
#'
#' @param endpoints Named list of \code{Endpoint} objects.
#' @param priority \code{NULL} (the order of \code{endpoints}) or a character
#'   vector of endpoint names in decreasing priority; names may be repeated
#'   with decreasing thresholds.
#' @param threshold \code{NULL} (0 for every level) or a numeric vector with
#'   one non-negative value per level; ignored (must be 0 or \code{NA}) for
#'   binary endpoints.
#' @return A list with \code{endpoints} (the endpoints in priority order) and
#'   \code{threshold}.
#' @keywords internal
#' @noRd
.check_priority <- function(endpoints, priority = NULL, threshold = NULL) {
  if (is.null(priority)) priority <- names(endpoints)
  if (!is.character(priority) || length(priority) == 0L || anyNA(priority) ||
      !all(priority %in% names(endpoints))) {
    stop("'priority' must be a character vector of endpoint names.", call. = FALSE)
  }
  eps <- unname(endpoints[priority])
  K <- length(eps)
  if (is.null(threshold)) threshold <- rep(0, K)
  if (!is.numeric(threshold) && !all(is.na(threshold))) {
    stop("'threshold' must be numeric.", call. = FALSE)
  }
  if (length(threshold) != K) {
    stop("'threshold' must have one value per element of 'priority'.", call. = FALSE)
  }
  threshold <- as.numeric(threshold)
  binary <- vapply(eps, function(e) e$type == "binary", logical(1))
  if (any(binary & !is.na(threshold) & threshold != 0)) {
    stop("The threshold of a binary endpoint must be 0 or NA.", call. = FALSE)
  }
  threshold[binary] <- 0
  if (anyNA(threshold) || any(!is.finite(threshold)) || any(threshold < 0)) {
    stop("The thresholds of time-to-event endpoints must be non-negative.", call. = FALSE)
  }
  for (nm in unique(priority[duplicated(priority)])) {
    if (any(diff(threshold[priority == nm]) >= 0)) {
      stop("An endpoint used more than once in 'priority' must have decreasing thresholds.",
           call. = FALSE)
    }
  }
  names(eps) <- priority
  list(endpoints = eps, threshold = threshold)
}
