#' Simulate single-arm cohorts with correlated endpoints and an adverse event
#'
#' @description
#' Generates patient-level data of several single-arm cohorts for many
#' simulated trials: progression-free survival (PFS), overall survival (OS) and
#' objective response, correlated within a patient, from the \code{CorOncoEndpoints}
#' package, and a binary adverse event that is independent of the other
#' endpoints. The data can be cut at a common calendar time of analysis.
#'
#' @details
#' Each cohort is described by an \code{OncoArm} object of the
#' \code{CorOncoEndpoints} package (see \code{\link[CorOncoEndpoints]{OncoArm}}),
#' which specifies the PFS median, the response rate, the association between
#' PFS and response and the OS model. The cohorts are generated independently by
#' \code{\link[CorOncoEndpoints]{rOncoEndpoints}}, one call per cohort, so that
#' each cohort can have its own accrual and dropout. With \code{seed}, cohort
#' \code{j} uses stream \code{j} of the random number generator seeded with
#' \code{seed}, and the results are reproducible.
#'
#' The adverse event of each patient is a Bernoulli variable with probability
#' \code{ae.rate} of the cohort, independent of PFS, OS and response, and is
#' taken as known at the analysis for every enrolled patient.
#'
#' With \code{cutoff}, the data are restricted to patients enrolled before the
#' calendar time \code{cutoff} (on the time scale of \code{a.time}, which
#' starts at 0), and PFS and OS are censored at the cutoff by
#' \code{\link[CorOncoEndpoints]{CutoffData}}; a response counts only if it was
#' observed before the cutoff. Accrual intervals that start later than 0 (for
#' example \code{a.time = list(c(0, 12), c(6, 18))}) describe cohorts enrolled
#' at different times.
#'
#' @param nsim Number of simulated trials.
#' @param n Integer vector of cohort sizes, one per cohort.
#' @param arms A list of \code{OncoArm} objects, one per cohort (or a single
#'   object). The names of the list are the cohort labels; unnamed cohorts are
#'   labeled \code{"Cohort1"}, \code{"Cohort2"}, and so on.
#' @param ae.rate Numeric vector with the probability of the adverse event in
#'   each cohort.
#' @param cutoff Calendar time of the analysis, or \code{NULL} for no cutoff.
#' @param a.time,a.rate,a.prop Accrual of each cohort, passed to
#'   \code{\link[CorOncoEndpoints]{rOncoEndpoints}}: \code{NULL}, a numeric
#'   vector used for every cohort, or a list with one vector per cohort.
#' @param d.hazard Hazard of an exponential dropout time, a scalar or one value
#'   per cohort.
#' @param seed Optional integer seed.
#' @return A data frame with one row per patient, ordered by \code{sim} and
#'   cohort, with columns \code{sim}, \code{group}, \code{accrual_time},
#'   \code{pfs_tte}, \code{pfs_event}, \code{os_tte}, \code{os_event},
#'   \code{response} (observed by the cutoff when \code{cutoff} is given) and
#'   \code{ae}.
#' @examples
#' arms <- list(
#'   Cohort1 = CorOncoEndpoints::OncoArm(pfs.median = 8, orr = 0.45, resp.cor = 0.4,
#'                                       death.prop = 0.15, os.median = 18),
#'   Cohort2 = CorOncoEndpoints::OncoArm(pfs.median = 6, orr = 0.30, resp.cor = 0.4,
#'                                       death.prop = 0.15, os.median = 15))
#' d <- SimCohorts(nsim = 2, n = c(30, 30), arms = arms, ae.rate = c(0.35, 0.20),
#'                 cutoff = 24, a.time = c(0, 12), seed = 1)
#' head(d)
#' table(d$sim, d$group)
#' @seealso \code{\link{SimSelection}}
#' @export
SimCohorts <- function(nsim, n, arms, ae.rate, cutoff = NULL, a.time = NULL,
                       a.rate = NULL, a.prop = NULL, d.hazard = 0, seed = NULL) {
  if (!is.numeric(nsim) || length(nsim) != 1L || is.na(nsim) || nsim < 1 ||
      nsim != round(nsim)) {
    stop("'nsim' must be a positive whole number.", call. = FALSE)
  }
  if (inherits(arms, "OncoArm")) arms <- list(arms)
  if (!is.list(arms) || length(arms) == 0L ||
      !all(vapply(arms, inherits, logical(1), what = "OncoArm"))) {
    stop("'arms' must be an OncoArm object or a list of them ",
         "(see CorOncoEndpoints::OncoArm()).", call. = FALSE)
  }
  k <- length(arms)
  lab <- names(arms)
  if (is.null(lab)) lab <- rep("", k)
  lab[is.na(lab) | lab == ""] <- paste0("Cohort", seq_len(k))[is.na(lab) | lab == ""]
  if (anyDuplicated(lab)) stop("The cohort labels must be unique.", call. = FALSE)
  if (!is.numeric(n) || length(n) != k || anyNA(n) || any(n < 1) || any(n != round(n))) {
    stop("'n' must contain one positive whole number per cohort.", call. = FALSE)
  }
  if (!is.numeric(ae.rate) || length(ae.rate) != k || anyNA(ae.rate) ||
      any(ae.rate < 0 | ae.rate > 1)) {
    stop("'ae.rate' must contain one probability per cohort.", call. = FALSE)
  }
  if (!is.numeric(d.hazard) || !length(d.hazard) %in% c(1L, k) || anyNA(d.hazard) ||
      any(d.hazard < 0)) {
    stop("'d.hazard' must be a non-negative scalar or have one value per cohort.",
         call. = FALSE)
  }
  d.hazard <- rep_len(d.hazard, k)
  if (!is.null(cutoff) && (!is.numeric(cutoff) || length(cutoff) != 1L || is.na(cutoff) ||
                           cutoff <= 0)) {
    stop("'cutoff' must be a positive number or NULL.", call. = FALSE)
  }
  if (!is.null(seed) && (!is.numeric(seed) || length(seed) != 1L || is.na(seed) ||
                         seed != round(seed))) {
    stop("'seed' must be a whole number or NULL.", call. = FALSE)
  }
  at <- .per_cohort(a.time, k, "a.time")
  ar <- .per_cohort(a.rate, k, "a.rate")
  ap <- .per_cohort(a.prop, k, "a.prop")
  parts <- vector("list", k)
  for (j in seq_len(k)) {
    dj <- CorOncoEndpoints::rOncoEndpoints(
      nsim = nsim, n = n[j], arms = stats::setNames(list(arms[[j]]), lab[j]),
      a.time = at[[j]], a.rate = ar[[j]], a.prop = ap[[j]], d.hazard = d.hazard[j],
      seed = seed, stream = if (is.null(seed)) NULL else j)
    # the adverse event continues the random number stream of the cohort
    dj$ae <- as.integer(dqrng::dqrunif(nrow(dj)) < ae.rate[j])
    parts[[j]] <- dj
  }
  dat <- do.call(rbind, parts)
  dat$group <- as.character(dat$group)
  dat$sim <- as.integer(dat$sim)
  if (is.null(cutoff)) {
    dat$response <- as.integer(dat$response)
  } else {
    dat <- CorOncoEndpoints::CutoffData(dat, cutoff)
    dat$response <- as.integer(dat$response_obs)
  }
  dat <- dat[order(dat$sim, match(dat$group, lab)), , drop = FALSE]
  out <- dat[, c("sim", "group", "accrual_time", "pfs_tte", "pfs_event", "os_tte",
                 "os_event", "response", "ae")]
  rownames(out) <- NULL
  out
}
