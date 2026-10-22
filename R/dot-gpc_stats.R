#' Win statistics and their standard errors (internal)
#'
#' Computes the proportions of pairs won, lost and tied, the net treatment
#' benefit, the win ratio and the win odds. The variances of the proportions
#' won and lost and their covariance are estimated from the first-order
#' H-decomposition of the two-sample U-statistics, without finite-sample
#' correction. The confidence interval of the net treatment benefit is computed
#' on the inverse hyperbolic tangent scale and that of the win ratio on the log
#' scale; the interval of the win odds is that of the net treatment benefit
#' transformed by \code{(1 + x) / (1 - x)}.
#'
#' @param pairs List returned by \code{.gpc_pairs()}.
#' @param conf.level Confidence level.
#' @return A named numeric vector with \code{p_win}, \code{p_loss},
#'   \code{p_tie}, \code{ntb}, \code{ntb_se}, \code{ntb_lower},
#'   \code{ntb_upper}, \code{wr}, \code{logwr_se}, \code{wr_lower},
#'   \code{wr_upper}, \code{wo}, \code{wo_lower} and \code{wo_upper}.
#' @keywords internal
#' @noRd
.gpc_stats <- function(pairs, conf.level = 0.95) {
  W <- pairs$win * 1
  L <- pairs$loss * 1
  m <- nrow(W)
  n <- ncol(W)
  pw <- mean(W)
  pl <- mean(L)
  hw1 <- rowMeans(W) - pw
  hw0 <- colMeans(W) - pw
  hl1 <- rowMeans(L) - pl
  hl0 <- colMeans(L) - pl
  vw <- sum(hw1 ^ 2) / m ^ 2 + sum(hw0 ^ 2) / n ^ 2
  vl <- sum(hl1 ^ 2) / m ^ 2 + sum(hl0 ^ 2) / n ^ 2
  cv <- sum(hw1 * hl1) / m ^ 2 + sum(hw0 * hl0) / n ^ 2
  z <- stats::qnorm(1 - (1 - conf.level) / 2)
  ntb <- pw - pl
  ntb_se <- sqrt(max(vw + vl - 2 * cv, 0))
  ntb_ci <- c(NA_real_, NA_real_)
  if (abs(ntb) < 1 && ntb_se > 0) {
    ntb_ci <- tanh(atanh(ntb) + c(-1, 1) * z * ntb_se / (1 - ntb ^ 2))
  }
  wr <- pw / pl
  logwr_se <- NA_real_
  wr_ci <- c(NA_real_, NA_real_)
  if (pw > 0 && pl > 0) {
    logwr_se <- sqrt(max(vw / pw ^ 2 + vl / pl ^ 2 - 2 * cv / (pw * pl), 0))
    wr_ci <- exp(log(wr) + c(-1, 1) * z * logwr_se)
  }
  wo <- (1 + ntb) / (1 - ntb)
  wo_ci <- (1 + ntb_ci) / (1 - ntb_ci)
  c(p_win = pw, p_loss = pl, p_tie = 1 - pw - pl, ntb = ntb, ntb_se = ntb_se,
    ntb_lower = ntb_ci[1], ntb_upper = ntb_ci[2], wr = wr, logwr_se = logwr_se,
    wr_lower = wr_ci[1], wr_upper = wr_ci[2], wo = wo, wo_lower = wo_ci[1],
    wo_upper = wo_ci[2])
}
