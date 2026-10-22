#' Check and complete the criteria of a benefit-risk score (internal)
#'
#' @param criteria Data frame with one row per component; see
#'   \code{\link{BenefitRisk}}.
#' @param endpoints Named list of \code{Endpoint} objects.
#' @param two.sample Logical: \code{TRUE} for components relative to a
#'   reference group.
#' @return A data frame with columns \code{endpoint}, \code{type},
#'   \code{higher.better}, \code{measure}, \code{time}, \code{target},
#'   \code{weight}, \code{cutoff}, \code{prior.a}, \code{prior.b} and
#'   \code{label}.
#' @keywords internal
#' @noRd
.check_criteria <- function(criteria, endpoints, two.sample) {
  if (!is.data.frame(criteria) || nrow(criteria) == 0L) {
    stop("'criteria' must be a data frame with one row per component.", call. = FALSE)
  }
  if (!all(c("endpoint", "target") %in% names(criteria))) {
    stop("'criteria' must have the columns 'endpoint' and 'target'.", call. = FALSE)
  }
  K <- nrow(criteria)
  ep <- as.character(criteria$endpoint)
  if (anyNA(ep) || !all(ep %in% names(endpoints))) {
    stop("Every 'endpoint' in 'criteria' must be the name of one of the 'endpoints'.",
         call. = FALSE)
  }
  type <- vapply(endpoints[ep], function(e) e$type, character(1), USE.NAMES = FALSE)
  hb <- vapply(endpoints[ep], function(e) e$higher.better, logical(1), USE.NAMES = FALSE)
  column <- function(name, default) {
    if (name %in% names(criteria)) criteria[[name]] else rep(default, K)
  }
  measure <- as.character(column("measure", NA_character_))
  miss <- is.na(measure)
  measure[miss] <- ifelse(type[miss] == "binary", "rate", "surv")
  ok <- (type == "binary" & measure == "rate") |
    (type == "tte" & measure %in% c("surv", "hr"))
  if (!all(ok)) {
    stop("'measure' must be \"rate\" for binary endpoints and \"surv\" or \"hr\" for ",
         "time-to-event endpoints.", call. = FALSE)
  }
  if (!two.sample && any(measure == "hr")) {
    stop("'measure' = \"hr\" requires a reference group.", call. = FALSE)
  }
  time <- as.numeric(column("time", NA_real_))
  surv <- measure == "surv"
  if (any(surv & (is.na(time) | !is.finite(time) | time <= 0))) {
    stop("'time' must be positive for the components with 'measure' = \"surv\".",
         call. = FALSE)
  }
  time[!surv] <- NA_real_
  target <- as.numeric(criteria$target)
  if (anyNA(target) || any(!is.finite(target))) {
    stop("'target' must be finite.", call. = FALSE)
  }
  bad <- if (two.sample) {
    (measure %in% c("rate", "surv") & abs(target) >= 1) | (measure == "hr" & target <= 0)
  } else {
    (measure == "rate" & (target < 0 | target > 1)) |
      (measure == "surv" & (target <= 0 | target >= 1))
  }
  if (any(bad)) {
    stop("'target' is outside its range: a rate in [0, 1] or a survival probability in ",
         "(0, 1) without a reference group, a margin in (-1, 1) or a positive hazard ",
         "ratio with a reference group.", call. = FALSE)
  }
  weight <- as.numeric(column("weight", 1 / K))
  if (anyNA(weight) || any(!is.finite(weight)) || any(weight < 0) || all(weight == 0)) {
    stop("'weight' must be non-negative and not all zero.", call. = FALSE)
  }
  cutoff <- as.numeric(column("cutoff", NA_real_))
  if (any(!is.na(cutoff) & (cutoff < 0 | cutoff > 1))) {
    stop("'cutoff' must be in [0, 1] or NA.", call. = FALSE)
  }
  pa <- as.numeric(column("prior.a", NA_real_))
  pb <- as.numeric(column("prior.b", NA_real_))
  pa[is.na(pa)] <- 0.5
  miss <- is.na(pb)
  pb[miss] <- ifelse(type[miss] == "binary", 0.5, 0)
  if (any(!is.finite(pa)) || any(!is.finite(pb)) || any(pa <= 0) || any(pb < 0) ||
      any(type == "binary" & pb <= 0)) {
    stop("'prior.a' must be positive and 'prior.b' non-negative (positive for binary ",
         "endpoints).", call. = FALSE)
  }
  label <- if ("label" %in% names(criteria)) {
    as.character(criteria$label)
  } else {
    ifelse(measure == "surv", paste0(ep, "_S", as.character(time)),
           ifelse(measure == "hr", paste0(ep, "_HR"), ep))
  }
  if (anyNA(label)) stop("'label' must not contain missing values.", call. = FALSE)
  data.frame(endpoint = ep, type = type, higher.better = hb, measure = measure,
             time = time, target = target, weight = weight, cutoff = cutoff,
             prior.a = pa, prior.b = pb, label = make.unique(label),
             stringsAsFactors = FALSE)
}
