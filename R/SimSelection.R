#' Benefit-risk scores and win statistics of simulated trials
#'
#' @description
#' For each simulated trial, computes the posterior benefit-risk score of
#' every cohort against target values and compares every other cohort with a
#' reference cohort by the difference of these scores, optionally by the
#' benefit-risk score relative to the reference cohort, and by generalized
#' pairwise comparisons. The results are summarized by
#' \code{\link{SelectionOC}} and \code{\link{CalibrateThreshold}}.
#'
#' @details
#' The reference cohort is the one chosen when no other cohort is shown to be
#' better, for example the cohort of the standard combination. The
#' benefit-risk scores are computed as in \code{\link{BenefitRisk}}, with
#' \code{criteria} for the scores against target values and
#' \code{criteria.ref} for the scores relative to the reference cohort. The win
#' statistics of a cohort are those of \code{\link{WinStat}} with the cohort as
#' treatment and the reference cohort as control. Every simulated trial must
#' contain patients of every cohort.
#'
#' @param data Patient-level data of many simulated trials, for example from
#'   \code{\link{SimCohorts}}.
#' @param endpoints An \code{\link{Endpoint}} object or a list of them.
#' @param criteria Data frame of the components of the benefit-risk score
#'   against target values; see \code{\link{BenefitRisk}}.
#' @param reference Name of the reference cohort.
#' @param cohorts Names of the cohorts compared, including \code{reference};
#'   by default all cohorts of \code{data} (in the order of the levels of a
#'   factor, otherwise in the order of appearance).
#' @param criteria.ref Optional data frame of the components of the
#'   benefit-risk score relative to the reference cohort.
#' @param priority,threshold,scoring Priority order, thresholds and scoring
#'   rule of the pairwise comparisons; see \code{\link{WinStat}}.
#' @param group,sim Names of the columns of \code{data} with the cohort and the
#'   simulated trial.
#' @param conf.level Confidence level of the lower bound of the net treatment
#'   benefit.
#' @param n.nodes Number of Gauss-Legendre nodes for probabilities of
#'   differences.
#' @param scores Logical: if \code{TRUE}, the posterior probabilities of the
#'   components are added to the output.
#' @return A data frame with one row per simulated trial and cohort. The
#'   statistics that compare a cohort with the reference cohort are \code{NA}
#'   in the rows of the reference cohort. With \code{scores = TRUE}, the
#'   posterior probabilities of the components are added after the columns
#'   below, in columns named \code{S:} (against target values) and \code{ref:}
#'   (relative to the reference cohort) followed by the label of the
#'   component. The columns are
#'   \item{sim}{The simulated trial.}
#'   \item{group}{The cohort.}
#'   \item{is_reference}{Whether the cohort is the reference cohort.}
#'   \item{br, adm}{Benefit-risk score and admissibility against target
#'     values.}
#'   \item{br_diff}{Difference of \code{br} from that of the reference
#'     cohort.}
#'   \item{br_ref, adm_ref}{Benefit-risk score and admissibility relative to
#'     the reference cohort (only with \code{criteria.ref}).}
#'   \item{p_win, p_loss, p_tie, ntb, ntb_se, ntb_lower, wr, wo}{Proportions
#'     of pairs won, lost and tied against the reference cohort, net treatment
#'     benefit with its standard error and lower confidence bound, win ratio
#'     and win odds.}
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
#' res <- SimSelection(d, eps, crit, reference = "Cohort2", criteria.ref = crit_ref)
#' head(res)
#' @seealso \code{\link{SelectionOC}}, \code{\link{CalibrateThreshold}}
#' @export
SimSelection <- function(data, endpoints, criteria, reference, cohorts = NULL,
                         criteria.ref = NULL, priority = NULL, threshold = NULL,
                         scoring = c("gehan", "peron"), group = "group", sim = "sim",
                         conf.level = 0.95, n.nodes = 200, scores = FALSE) {
  if (!is.data.frame(data)) stop("'data' must be a data frame.", call. = FALSE)
  for (v in list(group, sim)) {
    if (!.is_string(v) || !v %in% names(data)) {
      stop("'group' and 'sim' must be names of columns of 'data'.", call. = FALSE)
    }
  }
  scoring <- match.arg(scoring)
  if (!is.numeric(conf.level) || length(conf.level) != 1L || is.na(conf.level) ||
      conf.level <= 0 || conf.level >= 1) {
    stop("'conf.level' must be in (0, 1).", call. = FALSE)
  }
  g0 <- data[[group]]
  if (anyNA(g0)) stop("The column 'group' must not contain missing values.", call. = FALSE)
  lev <- if (is.factor(g0)) levels(droplevels(g0)) else unique(as.character(g0))
  if (is.null(cohorts)) cohorts <- lev
  if (!is.character(cohorts) || anyNA(cohorts) || anyDuplicated(cohorts) ||
      !all(cohorts %in% lev)) {
    stop("'cohorts' must be distinct names of cohorts in 'data'.", call. = FALSE)
  }
  if (!.is_string(reference) || !reference %in% cohorts) {
    stop("'reference' must be one of the cohorts compared.", call. = FALSE)
  }
  if (length(cohorts) < 2L) {
    stop("At least two cohorts, including 'reference', must be compared.", call. = FALSE)
  }
  g <- as.character(g0)
  keep <- g %in% cohorts
  d <- data[keep, , drop = FALSE]
  g <- g[keep]
  if (anyNA(d[[sim]])) stop("The column 'sim' must not contain missing values.", call. = FALSE)
  endpoints <- .check_endpoints(endpoints, d)
  crit <- .check_criteria(criteria, endpoints, two.sample = FALSE)
  crit_ref <- if (is.null(criteria.ref)) NULL else
    .check_criteria(criteria.ref, endpoints, two.sample = TRUE)
  pr <- .check_priority(endpoints, priority, threshold)
  G <- length(cohorts)
  r <- match(reference, cohorts)
  sims <- sort(unique(d[[sim]]))
  ns <- length(sims)
  si <- match(d[[sim]], sims)
  gi <- match(g, cohorts)
  key <- (si - 1L) * G + gi
  nkey <- G * ns
  if (ns == 0L || any(tabulate(key, nbins = nkey) == 0L)) {
    stop("Every simulated trial must contain patients of every cohort.", call. = FALSE)
  }
  # rows of the output: simulated trials, then cohorts (the groups of 'key')
  out <- data.frame(sim = rep(sims, each = G), group = rep(cohorts, ns),
                    is_reference = rep(seq_len(G) == r, ns), stringsAsFactors = FALSE)
  ref_key <- rep((seq_len(ns) - 1L) * G + r, each = G)
  oth <- which(!out$is_reference)
  s_tar <- .br_scores(d, endpoints, crit, key, nkey, seq_len(nkey), NULL, n.nodes)
  c_tar <- .br_composite(s_tar, crit)
  out$br <- c_tar$BR
  out$adm <- c_tar$admissible
  out$br_diff <- out$br - out$br[ref_key]
  out$br_diff[out$is_reference] <- NA_real_
  if (!is.null(crit_ref)) {
    s_ref <- matrix(NA_real_, nkey, nrow(crit_ref), dimnames = list(NULL, crit_ref$label))
    s_ref[oth, ] <- .br_scores(d, endpoints, crit_ref, key, nkey, oth, ref_key[oth], n.nodes)
    c_ref <- .br_composite(s_ref[oth, , drop = FALSE], crit_ref)
    out$br_ref <- NA_real_
    out$adm_ref <- NA
    out$br_ref[oth] <- c_ref$BR
    out$adm_ref[oth] <- c_ref$admissible
  }
  v <- c("p_win", "p_loss", "p_tie", "ntb", "ntb_se", "ntb_lower", "wr", "wo")
  gst <- matrix(NA_real_, nkey, length(v), dimnames = list(NULL, v))
  rows <- split(seq_len(nrow(d)), key)
  for (j in oth) {
    xc <- d[rows[[ref_key[j]]], , drop = FALSE]
    xt <- d[rows[[j]], , drop = FALSE]
    pairs <- .gpc_pairs(xt, xc, pr$endpoints, pr$threshold, scoring)
    gst[j, ] <- .gpc_stats(pairs, conf.level)[v]
  }
  for (w in v) out[[w]] <- unname(gst[, w])
  if (scores) {
    colnames(s_tar) <- paste0("S:", crit$label)
    out <- cbind(out, as.data.frame(s_tar, optional = TRUE))
    if (!is.null(crit_ref)) {
      colnames(s_ref) <- paste0("ref:", crit_ref$label)
      out <- cbind(out, as.data.frame(s_ref, optional = TRUE))
    }
  }
  rownames(out) <- NULL
  out
}
