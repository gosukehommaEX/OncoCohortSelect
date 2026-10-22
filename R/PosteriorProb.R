#' Posterior probability of a favorable value of an endpoint
#'
#' @description
#' Computes the posterior probability that a response rate, a survival
#' probability or a hazard ratio is favorable: above (or below) a target value
#' for one group, or better than in a reference group by a margin.
#'
#' @details
#' The posterior distributions are given by their parameters.
#' \itemize{
#'   \item \code{measure = "rate"}: the rate \code{p} has a beta posterior with
#'     shape parameters \code{a} and \code{b}, for example \code{a = a0 + x} and
#'     \code{b = b0 + n - x} for \code{x} responders among \code{n} patients and
#'     a \code{Beta(a0, b0)} prior.
#'   \item \code{measure = "surv"}: the event times are exponential with hazard
#'     \code{lambda}, which has a gamma posterior with shape \code{a} and rate
#'     \code{b}, for example \code{a = a0 + d} and \code{b = b0 + T} for
#'     \code{d} events and total follow-up time \code{T} and a
#'     \code{Gamma(a0, b0)} prior. The parameter is the survival probability
#'     \code{S(time) = exp(-lambda * time)}.
#'   \item \code{measure = "hr"}: the hazard ratio \code{lambda / lambda_ref} of
#'     two such exponential models; a reference group is required.
#' }
#'
#' Without a reference group (\code{a.ref} and \code{b.ref} are \code{NULL}),
#' the result is \code{P(p >= target)} or \code{P(S(time) >= target)} when
#' \code{higher.better = TRUE}, and \code{P(p <= target)} or
#' \code{P(S(time) <= target)} otherwise.
#'
#' With a reference group, the result is \code{P(theta - theta_ref >= target)}
#' when \code{higher.better = TRUE} and \code{P(theta - theta_ref <= target)}
#' otherwise, where \code{theta} is the rate or the survival probability and
#' \code{target} is a margin in \code{(-1, 1)}. For the hazard ratio, the result
#' is \code{P(lambda / lambda_ref <= target)} when \code{higher.better = TRUE}
#' (longer times are favorable) and \code{P(lambda / lambda_ref >= target)}
#' otherwise. The two posterior distributions are independent.
#'
#' One-sample probabilities and the probability of the hazard ratio are
#' computed in closed form (beta, gamma and F distributions). The probability
#' of a difference is a one-dimensional integral computed with an
#' \code{n.nodes}-point Gauss-Legendre rule on the probability scale of one of
#' the two posterior distributions; with the default 200 nodes the absolute
#' error is of the order of \code{1e-6} or smaller.
#'
#' @param measure \code{"rate"}, \code{"surv"} or \code{"hr"}.
#' @param a,b Parameters of the posterior distribution: beta shape parameters
#'   for \code{"rate"}, gamma shape and rate of the hazard for \code{"surv"}
#'   and \code{"hr"}. Positive numeric vectors.
#' @param target Target value of the rate or of the survival probability
#'   without a reference group; margin of the difference, or bound of the
#'   hazard ratio, with a reference group.
#' @param time Time of the survival probability, required for
#'   \code{measure = "surv"}.
#' @param a.ref,b.ref Parameters of the posterior distribution of the
#'   reference group, or \code{NULL} for a one-sample probability.
#' @param higher.better Logical: \code{TRUE} if higher rates or survival
#'   probabilities (longer times) are favorable.
#' @param n.nodes Number of Gauss-Legendre nodes for the probability of a
#'   difference.
#' @return Numeric vector of posterior probabilities. \code{a}, \code{b},
#'   \code{target}, \code{time}, \code{a.ref} and \code{b.ref} are recycled to
#'   a common length.
#' @references
#' Chakraborty, S., Dubey, A. K., Kumar, A. and Chan, I. (2026). A two-stage
#' dose optimization framework for oncology drug development with multiple
#' efficacy and safety endpoints via an integrated benefit-risk assessment.
#' \emph{Statistics in Biopharmaceutical Research}, published online.
#' \doi{10.1080/19466315.2026.2668381}
#' @examples
#' # P(ORR >= 0.3) with 18 responders among 40 patients and a Beta(0.5, 0.5) prior
#' PosteriorProb("rate", a = 0.5 + 18, b = 0.5 + 22, target = 0.3)
#'
#' # P(S(6) >= 0.5) with 20 events in 300 months of follow-up
#' PosteriorProb("surv", a = 0.5 + 20, b = 300, target = 0.5, time = 6)
#'
#' # P(AE rate - AE rate of the reference <= 0.1)
#' PosteriorProb("rate", a = 0.5 + 12, b = 0.5 + 28, target = 0.1,
#'               a.ref = 0.5 + 8, b.ref = 0.5 + 32, higher.better = FALSE)
#'
#' # P(HR <= 0.8)
#' PosteriorProb("hr", a = 0.5 + 20, b = 300, target = 0.8,
#'               a.ref = 0.5 + 25, b.ref = 280)
#' @seealso \code{\link{BenefitRisk}}
#' @export
PosteriorProb <- function(measure = c("rate", "surv", "hr"), a, b, target,
                          time = NULL, a.ref = NULL, b.ref = NULL,
                          higher.better = TRUE, n.nodes = 200) {
  measure <- match.arg(measure)
  pos <- function(x, name) {
    if (!is.numeric(x) || length(x) == 0L || anyNA(x) || any(!is.finite(x)) || any(x <= 0)) {
      stop("'", name, "' must be positive and finite.", call. = FALSE)
    }
  }
  pos(a, "a")
  pos(b, "b")
  two <- !is.null(a.ref) || !is.null(b.ref)
  if (two) {
    if (is.null(a.ref) || is.null(b.ref)) {
      stop("Give both 'a.ref' and 'b.ref' or neither.", call. = FALSE)
    }
    pos(a.ref, "a.ref")
    pos(b.ref, "b.ref")
  } else if (measure == "hr") {
    stop("'measure' = \"hr\" requires a reference group ('a.ref' and 'b.ref').", call. = FALSE)
  }
  if (!is.numeric(target) || length(target) == 0L || anyNA(target) || any(!is.finite(target))) {
    stop("'target' must be finite.", call. = FALSE)
  }
  if (measure == "surv") {
    if (is.null(time)) stop("'time' is required for 'measure' = \"surv\".", call. = FALSE)
    pos(time, "time")
  } else {
    time <- NULL
  }
  if (two) {
    bad <- if (measure == "hr") any(target <= 0) else any(abs(target) >= 1)
  } else {
    bad <- if (measure == "rate") any(target < 0 | target > 1) else any(target <= 0 | target >= 1)
  }
  if (bad) {
    stop("'target' is outside its range: a rate in [0, 1] or a survival probability ",
         "in (0, 1) for one group, a margin in (-1, 1) or a positive hazard ratio ",
         "with a reference group.", call. = FALSE)
  }
  if (!is.logical(higher.better) || length(higher.better) != 1L || is.na(higher.better)) {
    stop("'higher.better' must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.numeric(n.nodes) || length(n.nodes) != 1L || is.na(n.nodes) || n.nodes < 2 ||
      n.nodes != round(n.nodes)) {
    stop("'n.nodes' must be a whole number of at least 2.", call. = FALSE)
  }
  args <- list(a, b, target, time, a.ref, b.ref)
  lens <- lengths(args)
  len <- max(lens)
  if (any(lens > 0L & lens != 1L & lens != len)) {
    stop("'a', 'b', 'target', 'time', 'a.ref' and 'b.ref' must have length 1 or a common length.",
         call. = FALSE)
  }
  a <- rep_len(a, len)
  b <- rep_len(b, len)
  target <- rep_len(target, len)
  if (!two) {
    p_hi <- if (measure == "rate") {
      stats::pbeta(target, a, b, lower.tail = FALSE)
    } else {
      stats::pgamma(-log(target) / rep_len(time, len), a, rate = b)
    }
  } else if (measure == "hr") {
    ar <- rep_len(a.ref, len)
    br <- rep_len(b.ref, len)
    # (lambda * b / a) / (lambda_ref * b_ref / a_ref) has an F(2a, 2a_ref) distribution
    p_hi <- stats::pf(target * b * ar / (a * br), df1 = 2 * a, df2 = 2 * ar)
  } else {
    p_hi <- .prob_diff(measure, a, b, rep_len(a.ref, len), rep_len(b.ref, len), target,
                       time = if (is.null(time)) NULL else rep_len(time, len),
                       n.nodes = as.integer(n.nodes))
  }
  if (higher.better) p_hi else 1 - p_hi
}
