#' Posterior benefit-risk score of cohorts
#'
#' @description
#' Computes, for each cohort, the posterior probabilities that its endpoints
#' are favorable, the admissibility of the cohort and the composite
#' benefit-risk score of Chakraborty et al. (2026). Without a reference cohort
#' each cohort is assessed against target values; with a reference cohort each
#' other cohort is assessed by its difference from the reference.
#'
#' @details
#' \strong{Components.} Each row of \code{criteria} defines a component
#' \code{S_k}: the posterior probability that the parameter of an endpoint is
#' favorable (see \code{\link{PosteriorProb}}). For a binary endpoint the
#' parameter is the rate, with a beta prior and a binomial likelihood. For a
#' time-to-event endpoint the event times are taken as exponential, with a
#' gamma prior of the hazard; the parameter is the survival probability at
#' \code{time} (\code{measure = "surv"}) or, with a reference cohort, the
#' hazard ratio (\code{measure = "hr"}). Without a reference cohort, a
#' component is \code{P(parameter >= target)} for a favorable direction
#' \code{higher.better = TRUE} of the endpoint and \code{P(parameter <= target)}
#' otherwise; with a reference cohort, it is the probability that the
#' difference from the reference is at least \code{target} (or at most
#' \code{target}), or that the hazard ratio is at most \code{target}. A median
#' can be assessed through the survival probability at the target median with
#' \code{target = 0.5}.
#'
#' \strong{Columns of \code{criteria}.}
#' \itemize{
#'   \item \code{endpoint} (required): the name of an endpoint in
#'     \code{endpoints}. An endpoint can appear in several components, for
#'     example the survival probabilities at two times.
#'   \item \code{target} (required): the target value or margin.
#'   \item \code{measure}: \code{"rate"} (binary endpoints), \code{"surv"} or
#'     \code{"hr"} (time-to-event endpoints); by default \code{"rate"} and
#'     \code{"surv"}.
#'   \item \code{time}: the time of the survival probability.
#'   \item \code{weight}: the exponent of the component in the composite score;
#'     by default \code{1 / K} for \code{K} components.
#'   \item \code{cutoff}: the admissibility cutoff of the component, or
#'     \code{NA} for none.
#'   \item \code{prior.a}, \code{prior.b}: the parameters of the prior: beta
#'     shape parameters (default 0.5 and 0.5), or gamma shape and rate of the
#'     hazard (default 0.5 and 0).
#'   \item \code{label}: the name of the component in the output; by default
#'     the endpoint name, followed by \code{_S} and the time for survival
#'     probabilities (for example \code{PFS_S6}) and by \code{_HR} for hazard
#'     ratios.
#' }
#'
#' \strong{Composite score and admissibility.} The benefit-risk score is
#' \code{BR = prod(S_k ^ weight_k)}. With equal weights summing to 1 it is the
#' geometric mean of the components. The score of Chakraborty et al. (2026),
#' the geometric mean of the efficacy components times the geometric mean of
#' the safety components, is obtained with weights \code{1 / K_efficacy} and
#' \code{1 / K_safety}. A cohort is admissible when every component with a
#' cutoff satisfies \code{S_k >= cutoff_k}; the cutoff of a safety component of
#' the form \code{P(Delta >= t) < p} in Chakraborty et al. (2026) is
#' \code{1 - p}. Without a reference cohort, the admissible cohort with the
#' highest score is marked as selected.
#'
#' @param data Patient-level data frame with one row per patient.
#' @param endpoints An \code{\link{Endpoint}} object or a list of them.
#' @param criteria Data frame of the components; see Details.
#' @param group Name of the column of \code{data} with the cohort.
#' @param reference \code{NULL} for scores against target values, or the
#'   cohort used as the reference.
#' @param n.nodes Number of Gauss-Legendre nodes for probabilities of
#'   differences.
#' @return A data frame with one row per cohort (other than the reference)
#'   and columns \code{group}, \code{reference} (with a reference cohort), one
#'   column per component with its posterior probability, \code{admissible},
#'   \code{BR} and, without a reference cohort, \code{selected}.
#' @references
#' Chakraborty, S., Dubey, A. K., Kumar, A. and Chan, I. (2026). A two-stage
#' dose optimization framework for oncology drug development with multiple
#' efficacy and safety endpoints via an integrated benefit-risk assessment.
#' \emph{Statistics in Biopharmaceutical Research}, published online.
#' \doi{10.1080/19466315.2026.2668381}
#' @examples
#' set.seed(1)
#' d <- data.frame(group = rep(c("Cohort1", "Cohort2"), each = 40),
#'                 pfs_tte = rexp(80, log(2) / rep(c(8, 6), each = 40)),
#'                 pfs_event = 1,
#'                 response = rbinom(80, 1, rep(c(0.45, 0.30), each = 40)),
#'                 ae = rbinom(80, 1, rep(c(0.35, 0.20), each = 40)))
#' eps <- list(Endpoint("PFS", "tte", time = "pfs_tte", event = "pfs_event"),
#'             Endpoint("ORR", "binary", var = "response"),
#'             Endpoint("AE", "binary", var = "ae", higher.better = FALSE))
#'
#' # against target values
#' crit <- data.frame(endpoint = c("ORR", "PFS", "AE"), target = c(0.3, 0.5, 0.3),
#'                    time = c(NA, 6, NA), cutoff = c(0.5, 0.5, 0.5))
#' BenefitRisk(d, eps, crit)
#'
#' # Cohort1 relative to Cohort2
#' crit_ref <- data.frame(endpoint = c("ORR", "PFS", "AE"),
#'                        measure = c("rate", "hr", "rate"),
#'                        target = c(0.1, 0.8, 0.1))
#' BenefitRisk(d, eps, crit_ref, reference = "Cohort2")
#' @seealso \code{\link{PosteriorProb}}, \code{\link{WinStat}},
#'   \code{\link{SimSelection}}
#' @export
BenefitRisk <- function(data, endpoints, criteria, group = "group",
                        reference = NULL, n.nodes = 200) {
  if (!is.data.frame(data)) stop("'data' must be a data frame.", call. = FALSE)
  if (!.is_string(group) || !group %in% names(data)) {
    stop("'group' must be the name of a column of 'data'.", call. = FALSE)
  }
  endpoints <- .check_endpoints(endpoints, data)
  crit <- .check_criteria(criteria, endpoints, two.sample = !is.null(reference))
  g <- data[[group]]
  if (anyNA(g)) stop("The column 'group' must not contain missing values.", call. = FALSE)
  lev <- if (is.factor(g)) levels(droplevels(g)) else unique(as.character(g))
  key <- match(as.character(g), lev)
  G <- length(lev)
  if (is.null(reference)) {
    trt <- seq_len(G)
    ref <- NULL
  } else {
    if (!.is_string(reference) || !reference %in% lev) {
      stop("'reference' must be one of the cohorts in 'data'.", call. = FALSE)
    }
    if (G < 2L) stop("'data' must contain a cohort other than 'reference'.", call. = FALSE)
    r <- match(reference, lev)
    trt <- setdiff(seq_len(G), r)
    ref <- rep(r, length(trt))
  }
  S <- .br_scores(data, endpoints, crit, key, G, trt, ref, n.nodes)
  comp <- .br_composite(S, crit)
  out <- data.frame(group = lev[trt], stringsAsFactors = FALSE)
  if (!is.null(reference)) out$reference <- reference
  out <- cbind(out, as.data.frame(S, optional = TRUE))
  out$admissible <- comp$admissible
  out$BR <- comp$BR
  if (is.null(reference)) {
    out$selected <- FALSE
    cand <- which(out$admissible %in% TRUE)
    if (length(cand)) out$selected[cand[which.max(out$BR[cand])]] <- TRUE
  }
  rownames(out) <- NULL
  out
}
