#' Posterior probability of a difference between two groups (internal)
#'
#' Computes \code{P(theta - theta_ref >= margin)} for independent posterior
#' distributions of a parameter in two groups: a response rate with a beta
#' posterior (\code{measure = "rate"}), or a survival probability
#' \code{exp(-lambda * time)} with a gamma posterior of the hazard
#' \code{lambda} (\code{measure = "surv"}).
#'
#' The probability is an integral over the probability scale of one of the two
#' posterior distributions (the one with the smaller spread of the parameter),
#' \code{int_0^1 P(theta_ref <= Q(u) - margin) du}, where \code{Q} is the
#' quantile function of \code{theta}, or the analogous integral over the
#' reference group. The range in which the integrand is 0 or 1 is excluded and
#' the remaining range is integrated with an \code{n.nodes}-point
#' Gauss-Legendre rule.
#'
#' @param measure \code{"rate"} or \code{"surv"}.
#' @param a,b Parameters of the posterior distribution of the group: beta
#'   shape parameters, or gamma shape and rate of the hazard.
#' @param a.ref,b.ref The same for the reference group.
#' @param margin Margin of the difference, in \code{(-1, 1)}.
#' @param time Time of the survival probability (\code{measure = "surv"}).
#' @param n.nodes Number of Gauss-Legendre nodes.
#' @return Numeric vector of probabilities. All arguments except
#'   \code{measure} and \code{n.nodes} are recycled to a common length.
#' @keywords internal
#' @noRd
.prob_diff <- function(measure, a, b, a.ref, b.ref, margin, time = NULL,
                       n.nodes = 200L) {
  len <- max(length(a), length(b), length(a.ref), length(b.ref), length(margin),
             length(time))
  a <- rep_len(a, len)
  b <- rep_len(b, len)
  ar <- rep_len(a.ref, len)
  br <- rep_len(b.ref, len)
  m <- rep_len(margin, len)
  gl <- .gauss_legendre(n.nodes)
  if (measure == "rate") {
    q <- function(u, s1, s2) stats::qbeta(u, s1, s2)
    spread_t <- q(0.8413, a, b) - q(0.1587, a, b)
    spread_r <- q(0.8413, ar, br) - q(0.1587, ar, br)
    # outer integral over the group: the integrand is 0 below theta = margin
    # and 1 above theta = 1 + margin
    lo_t <- stats::pbeta(pmax(m, 0), a, b)
    hi_t <- stats::pbeta(pmin(1 + m, 1), a, b)
    const_t <- 1 - hi_t
    f_t <- function(u, i) {
      stats::pbeta(stats::qbeta(u, a[i], b[i]) - m[i], ar[i], br[i])
    }
    # outer integral over the reference group: the integrand is 1 below
    # theta_ref = -margin and 0 above theta_ref = 1 - margin
    lo_r <- stats::pbeta(pmax(-m, 0), ar, br)
    hi_r <- stats::pbeta(pmin(1 - m, 1), ar, br)
    const_r <- lo_r
    f_r <- function(u, i) {
      stats::pbeta(stats::qbeta(u, ar[i], br[i]) + m[i], a[i], b[i], lower.tail = FALSE)
    }
  } else {
    tm <- rep_len(time, len)
    s_of <- function(p, sh, rt) exp(-tm * stats::qgamma(p, sh, rate = rt))
    spread_t <- s_of(0.1587, a, b) - s_of(0.8413, a, b)
    spread_r <- s_of(0.1587, ar, br) - s_of(0.8413, ar, br)
    # outer integral over the group: the integrand is 1 when S >= 1 + margin
    # (margin < 0) and 0 when S <= margin (margin > 0)
    lo_t <- ifelse(m < 0, stats::pgamma(-log1p(pmin(m, 0)) / tm, a, rate = b), 0)
    hi_t <- ifelse(m > 0, stats::pgamma(-log(pmax(m, 1e-300)) / tm, a, rate = b), 1)
    const_t <- lo_t
    f_t <- function(u, i) {
      s <- exp(-tm[i] * stats::qgamma(u, a[i], rate = b[i])) - m[i]
      stats::pgamma(-log(pmax(s, 1e-300)) / tm[i], ar[i], rate = br[i], lower.tail = FALSE)
    }
    # outer integral over the reference group: the integrand is 0 when
    # S_ref >= 1 - margin (margin > 0) and 1 when S_ref <= -margin (margin < 0)
    lo_r <- ifelse(m > 0, stats::pgamma(-log1p(-pmax(m, 0)) / tm, ar, rate = br), 0)
    hi_r <- ifelse(m < 0, stats::pgamma(-log(pmax(-m, 1e-300)) / tm, ar, rate = br), 1)
    const_r <- 1 - hi_r
    f_r <- function(u, i) {
      s <- exp(-tm[i] * stats::qgamma(u, ar[i], rate = br[i])) + m[i]
      stats::pgamma(-log(pmax(s, 1e-300)) / tm[i], a[i], rate = b[i])
    }
  }
  use_t <- spread_t <= spread_r
  lo <- ifelse(use_t, lo_t, lo_r)
  hi <- ifelse(use_t, hi_t, hi_r)
  out <- ifelse(use_t, const_t, const_r)
  width <- hi - lo
  for (grp in c(TRUE, FALSE)) {
    i <- which(use_t == grp & width > 0)
    if (!length(i)) next
    # nodes in rows, one column per element
    u <- outer((gl$x + 1) / 2, width[i]) + rep(lo[i], each = n.nodes)
    ii <- rep(i, each = n.nodes)
    v <- if (grp) f_t(as.vector(u), ii) else f_r(as.vector(u), ii)
    v <- matrix(v, n.nodes, length(i))
    out[i] <- out[i] + width[i] / 2 * colSums(v * gl$w)
  }
  pmin(pmax(out, 0), 1)
}
