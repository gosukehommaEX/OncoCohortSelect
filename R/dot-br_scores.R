#' Component scores of the benefit-risk score (internal)
#'
#' Computes the posterior probability of each component of the criteria for
#' the groups \code{trt}, without a reference group or relative to the groups
#' \code{ref}.
#'
#' @param data Data frame.
#' @param endpoints Named list of \code{Endpoint} objects.
#' @param crit Criteria returned by \code{.check_criteria()}.
#' @param key Integer vector with the group of each row of \code{data}.
#' @param nkey Number of groups.
#' @param trt Integer vector of the groups to score.
#' @param ref \code{NULL}, or an integer vector of the same length as
#'   \code{trt} with the reference group of each.
#' @param n.nodes Number of Gauss-Legendre nodes.
#' @return A matrix with one row per element of \code{trt} and one column per
#'   component (named by \code{crit$label}).
#' @keywords internal
#' @noRd
.br_scores <- function(data, endpoints, crit, key, nkey, trt, ref = NULL,
                       n.nodes = 200L) {
  K <- nrow(crit)
  S <- matrix(NA_real_, length(trt), K, dimnames = list(NULL, crit$label))
  stats_by_ep <- list()
  for (k in seq_len(K)) {
    e <- endpoints[[crit$endpoint[k]]]
    if (is.null(stats_by_ep[[e$name]])) {
      stats_by_ep[[e$name]] <- .suff_stats(data, e, key, nkey)
    }
    st <- stats_by_ep[[e$name]]
    a <- crit$prior.a[k] + st$s1
    b <- if (e$type == "binary") crit$prior.b[k] + st$s2 - st$s1 else crit$prior.b[k] + st$s2
    time <- if (crit$measure[k] == "surv") crit$time[k] else NULL
    S[, k] <- if (is.null(ref)) {
      PosteriorProb(crit$measure[k], a[trt], b[trt], target = crit$target[k], time = time,
                    higher.better = e$higher.better, n.nodes = n.nodes)
    } else {
      PosteriorProb(crit$measure[k], a[trt], b[trt], target = crit$target[k], time = time,
                    a.ref = a[ref], b.ref = b[ref], higher.better = e$higher.better,
                    n.nodes = n.nodes)
    }
  }
  S
}
