#' Net treatment benefit, win ratio and win odds of prioritized endpoints
#'
#' @description
#' Compares every patient of one cohort (\code{treatment}) with every patient
#' of another cohort (\code{control}) on prioritized endpoints (generalized
#' pairwise comparisons, Buyse 2010) and computes the net treatment benefit,
#' the win ratio (Pocock et al. 2012) and the win odds (Brunner et al. 2021)
#' with standard errors and confidence intervals.
#'
#' @details
#' A pair is compared on the endpoints in the order of \code{priority}. The
#' first endpoint that decides the pair determines a win or a loss of the
#' treatment patient; a pair that no endpoint decides is a tie. An endpoint can
#' appear more than once, for example with a large threshold first and a
#' threshold of 0 later.
#'
#' A binary endpoint decides a pair when the two patients have different
#' values; a pair with a missing value is undecided. A time-to-event endpoint
#' is scored by the rule of Gehan (1965): the pair is decided when the patient
#' with the shorter observed time has an event and the difference of the
#' observed times is at least the threshold. With a threshold of 0 the
#' difference must be positive, and a censored time equal to an event time
#' counts as longer. These rules agree with the Gehan scoring rule of the
#' \code{BuyseTest} package.
#'
#' With \code{p_win}, \code{p_loss} and \code{p_tie} the proportions of pairs
#' won, lost and tied by the treatment patient, the net treatment benefit is
#' \code{p_win - p_loss}, the win ratio \code{p_win / p_loss} and the win odds
#' \code{(p_win + p_tie / 2) / (p_loss + p_tie / 2)}. Their standard errors
#' are computed from the first-order H-decomposition of the two-sample
#' U-statistics (Bebu and Lachin 2016), the standard errors of the win ratio
#' and the win odds by the delta method. The confidence interval of the net
#' treatment benefit is
#' computed on the inverse hyperbolic tangent scale, that of the win ratio on
#' the log scale, and that of the win odds is the interval of the net treatment
#' benefit transformed by \code{(1 + x) / (1 - x)}.
#'
#' @param data Patient-level data frame with one row per patient.
#' @param endpoints An \code{\link{Endpoint}} object or a list of them.
#' @param treatment,control Names of the two cohorts compared, values of the
#'   column \code{group}.
#' @param group Name of the column of \code{data} with the cohort.
#' @param priority Character vector of endpoint names in decreasing priority;
#'   by default the order of \code{endpoints}.
#' @param threshold Numeric vector of thresholds, one per element of
#'   \code{priority}: the minimal difference of times that decides a pair on a
#'   time-to-event endpoint (0 or \code{NA} for binary endpoints). By default
#'   0 for every endpoint.
#' @param conf.level Confidence level of the intervals.
#' @return A list with elements
#'   \item{estimate}{Named vector with \code{p_win}, \code{p_loss},
#'     \code{p_tie}, \code{ntb}, \code{wr} and \code{wo}.}
#'   \item{ci}{Data frame with the estimate, standard error and confidence
#'     interval of the net treatment benefit (\code{NTB}), the win ratio
#'     (\code{WR}) and the win odds (\code{WO}).}
#'   \item{by.endpoint}{Data frame with, for each priority level, the
#'     proportions of all pairs won and lost at that level and the proportion
#'     of pairs still undecided after it.}
#'   \item{n}{Named vector with the numbers of treatment and control patients
#'     and of pairs.}
#' @references
#' Buyse, M. (2010). Generalized pairwise comparisons of prioritized outcomes
#' in the two-sample problem. \emph{Statistics in Medicine}, 29, 3245-3257.
#' \doi{10.1002/sim.3923}
#'
#' Pocock, S. J., Ariti, C. A., Collier, T. J. and Wang, D. (2012). The win
#' ratio: a new approach to the analysis of composite endpoints in clinical
#' trials based on clinical priorities. \emph{European Heart Journal}, 33,
#' 176-182. \doi{10.1093/eurheartj/ehr352}
#'
#' Brunner, E., Vandemeulebroecke, M. and \enc{Mütze}{Mutze}, T. (2021). Win odds:
#' an adaptation of the win ratio to include ties. \emph{Statistics in
#' Medicine}, 40, 3367-3384. \doi{10.1002/sim.8967}
#'
#' Bebu, I. and Lachin, J. M. (2016). Large sample inference for a win ratio
#' analysis of a composite outcome based on prioritized components.
#' \emph{Biostatistics}, 17, 178-187. \doi{10.1093/biostatistics/kxv032}
#'
#' Gehan, E. A. (1965). A generalized Wilcoxon test for comparing arbitrarily
#' singly-censored samples. \emph{Biometrika}, 52, 203-223.
#' \doi{10.1093/biomet/52.1-2.203}
#' @examples
#' set.seed(1)
#' d <- data.frame(group = rep(c("Cohort1", "Cohort2"), each = 40),
#'                 os_tte = rexp(80, log(2) / rep(c(18, 15), each = 40)),
#'                 os_event = rbinom(80, 1, 0.6),
#'                 response = rbinom(80, 1, rep(c(0.45, 0.30), each = 40)),
#'                 ae = rbinom(80, 1, rep(c(0.35, 0.20), each = 40)))
#' eps <- list(Endpoint("OS", "tte", time = "os_tte", event = "os_event"),
#'             Endpoint("ORR", "binary", var = "response"),
#'             Endpoint("AE", "binary", var = "ae", higher.better = FALSE))
#' res <- WinStat(d, eps, treatment = "Cohort1", control = "Cohort2")
#' res$ci
#' res$by.endpoint
#'
#' # response first, then OS with a threshold of 3 months
#' WinStat(d, eps, treatment = "Cohort1", control = "Cohort2",
#'         priority = c("ORR", "OS", "AE"), threshold = c(0, 3, 0))$estimate
#' @seealso \code{\link{BenefitRisk}}, \code{\link{SimSelection}}
#' @export
WinStat <- function(data, endpoints, treatment, control, group = "group",
                    priority = NULL, threshold = NULL, conf.level = 0.95) {
  if (!is.data.frame(data)) stop("'data' must be a data frame.", call. = FALSE)
  if (!.is_string(group) || !group %in% names(data)) {
    stop("'group' must be the name of a column of 'data'.", call. = FALSE)
  }
  if (!.is_string(treatment) || !.is_string(control) || treatment == control) {
    stop("'treatment' and 'control' must be the names of two different cohorts.",
         call. = FALSE)
  }
  if (!is.numeric(conf.level) || length(conf.level) != 1L || is.na(conf.level) ||
      conf.level <= 0 || conf.level >= 1) {
    stop("'conf.level' must be in (0, 1).", call. = FALSE)
  }
  endpoints <- .check_endpoints(endpoints, data)
  pr <- .check_priority(endpoints, priority, threshold)
  g <- as.character(data[[group]])
  it <- which(g == treatment)
  ic <- which(g == control)
  if (!length(it) || !length(ic)) {
    stop("'data' must contain patients of both 'treatment' and 'control'.", call. = FALSE)
  }
  pairs <- .gpc_pairs(data[it, , drop = FALSE], data[ic, , drop = FALSE],
                      pr$endpoints, pr$threshold)
  st <- .gpc_stats(pairs, conf.level)
  np <- length(it) * length(ic)
  ci <- data.frame(
    statistic = c("NTB", "WR", "WO"),
    estimate = unname(st[c("ntb", "wr", "wo")]),
    se = unname(c(st["ntb_se"], st["wr"] * st["logwr_se"],
                  2 * st["ntb_se"] / (1 - st["ntb"]) ^ 2)),
    lower = unname(st[c("ntb_lower", "wr_lower", "wo_lower")]),
    upper = unname(st[c("ntb_upper", "wr_upper", "wo_upper")]),
    stringsAsFactors = FALSE)
  win <- pairs$win.k / np
  loss <- pairs$loss.k / np
  by_ep <- data.frame(priority = seq_along(win), endpoint = names(pr$endpoints),
                      threshold = pr$threshold, win = win, loss = loss,
                      undecided = 1 - cumsum(win + loss), stringsAsFactors = FALSE)
  list(estimate = st[c("p_win", "p_loss", "p_tie", "ntb", "wr", "wo")],
       ci = ci, by.endpoint = by_ep,
       n = c(treatment = length(it), control = length(ic), pairs = np))
}
