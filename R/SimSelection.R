#' Benefit-risk scores and win statistics of simulated trials
#'
#' @description
#' For each simulated trial, compares a treatment cohort with a control cohort
#' by the posterior benefit-risk score against target values (both cohorts),
#' optionally by the benefit-risk score of the treatment cohort relative to the
#' control cohort, and by generalized pairwise comparisons. The results are
#' summarized by \code{\link{SelectionOC}} and \code{\link{CalibrateThreshold}}.
#'
#' @details
#' The benefit-risk scores are computed as in \code{\link{BenefitRisk}}, with
#' \code{criteria} for the scores against target values and
#' \code{criteria.ref} for the score relative to the control cohort. The win
#' statistics are computed as in \code{\link{WinStat}}. Every simulated trial
#' must contain patients of both cohorts.
#'
#' @param data Patient-level data of many simulated trials, for example from
#'   \code{\link{SimCohorts}}.
#' @param endpoints An \code{\link{Endpoint}} object or a list of them.
#' @param criteria Data frame of the components of the benefit-risk score
#'   against target values; see \code{\link{BenefitRisk}}.
#' @param treatment,control Names of the two cohorts compared.
#' @param criteria.ref Optional data frame of the components of the
#'   benefit-risk score of \code{treatment} relative to \code{control}.
#' @param priority,threshold Priority order and thresholds of the pairwise
#'   comparisons; see \code{\link{WinStat}}.
#' @param group,sim Names of the columns of \code{data} with the cohort and the
#'   simulated trial.
#' @param conf.level Confidence level of the lower bound of the net treatment
#'   benefit.
#' @param n.nodes Number of Gauss-Legendre nodes for probabilities of
#'   differences.
#' @param scores Logical: if \code{TRUE}, the posterior probabilities of the
#'   components are added to the output.
#' @return A data frame with one row per simulated trial. With
#'   \code{scores = TRUE}, the posterior probabilities of the components are
#'   added after the columns below, in columns named \code{trt:}, \code{ctl:}
#'   and \code{ref:} followed by the label of the component. The columns are
#'   \item{sim}{The simulated trial.}
#'   \item{br_trt, br_ctl}{Benefit-risk scores against target values.}
#'   \item{adm_trt, adm_ctl}{Admissibility against target values.}
#'   \item{br_diff}{\code{br_trt - br_ctl}.}
#'   \item{br_ref, adm_ref}{Benefit-risk score and admissibility of the
#'     treatment cohort relative to the control cohort (only with
#'     \code{criteria.ref}).}
#'   \item{p_win, p_loss, p_tie, ntb, ntb_se, ntb_lower, wr, wo}{Proportions
#'     of pairs won, lost and tied, net treatment benefit with its standard
#'     error and lower confidence bound, win ratio and win odds.}
#' @examples
#' arms <- list(
#'   Cohort1 = CorOncoEndpoints::OncoArm(pfs.median = 8, orr = 0.45, resp.cor = 0.4,
#'                                       death.prop = 0.15, os.median = 18),
#'   Cohort2 = CorOncoEndpoints::OncoArm(pfs.median = 6, orr = 0.30, resp.cor = 0.4,
#'                                       death.prop = 0.15, os.median = 15))
#' d <- SimCohorts(nsim = 20, n = c(40, 40), arms = arms, ae.rate = c(0.35, 0.20),
#'                 cutoff = 24, a.time = c(0, 12), seed = 1)
#' eps <- list(Endpoint("OS", "tte", time = "os_tte", event = "os_event"),
#'             Endpoint("PFS", "tte", time = "pfs_tte", event = "pfs_event"),
#'             Endpoint("ORR", "binary", var = "response"),
#'             Endpoint("AE", "binary", var = "ae", higher.better = FALSE))
#' crit <- data.frame(endpoint = c("ORR", "PFS", "AE"), target = c(0.3, 0.5, 0.3),
#'                    time = c(NA, 6, NA))
#' crit_ref <- data.frame(endpoint = c("ORR", "PFS", "AE"),
#'                        measure = c("rate", "hr", "rate"),
#'                        target = c(0.1, 0.8, 0.1))
#' res <- SimSelection(d, eps, crit, treatment = "Cohort1", control = "Cohort2",
#'                     criteria.ref = crit_ref)
#' head(res)
#' @seealso \code{\link{SelectionOC}}, \code{\link{CalibrateThreshold}}
#' @export
SimSelection <- function(data, endpoints, criteria, treatment, control,
                         criteria.ref = NULL, priority = NULL, threshold = NULL,
                         group = "group", sim = "sim", conf.level = 0.95,
                         n.nodes = 200, scores = FALSE) {
  if (!is.data.frame(data)) stop("'data' must be a data frame.", call. = FALSE)
  for (v in c(group, sim)) {
    if (!.is_string(v) || !v %in% names(data)) {
      stop("'group' and 'sim' must be names of columns of 'data'.", call. = FALSE)
    }
  }
  if (!.is_string(treatment) || !.is_string(control) || treatment == control) {
    stop("'treatment' and 'control' must be the names of two different cohorts.",
         call. = FALSE)
  }
  if (!is.numeric(conf.level) || length(conf.level) != 1L || is.na(conf.level) ||
      conf.level <= 0 || conf.level >= 1) {
    stop("'conf.level' must be in (0, 1).", call. = FALSE)
  }
  g <- as.character(data[[group]])
  d <- data[g %in% c(treatment, control), , drop = FALSE]
  g <- g[g %in% c(treatment, control)]
  if (anyNA(d[[sim]])) stop("The column 'sim' must not contain missing values.", call. = FALSE)
  endpoints <- .check_endpoints(endpoints, d)
  crit <- .check_criteria(criteria, endpoints, two.sample = FALSE)
  crit_ref <- if (is.null(criteria.ref)) NULL else
    .check_criteria(criteria.ref, endpoints, two.sample = TRUE)
  pr <- .check_priority(endpoints, priority, threshold)
  sims <- sort(unique(d[[sim]]))
  ns <- length(sims)
  si <- match(d[[sim]], sims)
  gi <- match(g, c(treatment, control))
  key <- (si - 1L) * 2L + gi
  nkey <- 2L * ns
  if (ns == 0L || any(tabulate(key, nbins = nkey) == 0L)) {
    stop("Every simulated trial must contain patients of both 'treatment' and 'control'.",
         call. = FALSE)
  }
  it <- seq.int(1L, nkey, by = 2L)
  ic <- it + 1L
  s_trt <- .br_scores(d, endpoints, crit, key, nkey, it, NULL, n.nodes)
  s_ctl <- .br_scores(d, endpoints, crit, key, nkey, ic, NULL, n.nodes)
  c_trt <- .br_composite(s_trt, crit)
  c_ctl <- .br_composite(s_ctl, crit)
  out <- data.frame(sim = sims, br_trt = c_trt$BR, br_ctl = c_ctl$BR,
                    adm_trt = c_trt$admissible, adm_ctl = c_ctl$admissible)
  out$br_diff <- out$br_trt - out$br_ctl
  if (!is.null(crit_ref)) {
    s_ref <- .br_scores(d, endpoints, crit_ref, key, nkey, it, ic, n.nodes)
    c_ref <- .br_composite(s_ref, crit_ref)
    out$br_ref <- c_ref$BR
    out$adm_ref <- c_ref$admissible
  }
  rows <- split(seq_len(nrow(d)), si)
  gst <- do.call(rbind, lapply(rows, function(r) {
    pairs <- .gpc_pairs(d[r[gi[r] == 1L], , drop = FALSE], d[r[gi[r] == 2L], , drop = FALSE],
                        pr$endpoints, pr$threshold)
    .gpc_stats(pairs, conf.level)
  }))
  for (v in c("p_win", "p_loss", "p_tie", "ntb", "ntb_se", "ntb_lower", "wr", "wo")) {
    out[[v]] <- unname(gst[, v])
  }
  if (scores) {
    colnames(s_trt) <- paste0("trt:", crit$label)
    colnames(s_ctl) <- paste0("ctl:", crit$label)
    out <- cbind(out, as.data.frame(s_trt, optional = TRUE),
                 as.data.frame(s_ctl, optional = TRUE))
    if (!is.null(crit_ref)) {
      colnames(s_ref) <- paste0("ref:", crit_ref$label)
      out <- cbind(out, as.data.frame(s_ref, optional = TRUE))
    }
  }
  rownames(out) <- NULL
  out
}
