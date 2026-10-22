# Posterior probability of a favorable value of an endpoint

Computes the posterior probability that a response rate, a survival
probability or a hazard ratio is favorable: above (or below) a target
value for one group, or better than in a reference group by a margin.

## Usage

``` r
PosteriorProb(
  measure = c("rate", "surv", "hr"),
  a,
  b,
  target,
  time = NULL,
  a.ref = NULL,
  b.ref = NULL,
  higher.better = TRUE,
  n.nodes = 200
)
```

## Arguments

- measure:

  `"rate"`, `"surv"` or `"hr"`.

- a, b:

  Parameters of the posterior distribution: beta shape parameters for
  `"rate"`, gamma shape and rate of the hazard for `"surv"` and `"hr"`.
  Positive numeric vectors.

- target:

  Target value of the rate or of the survival probability without a
  reference group; margin of the difference, or bound of the hazard
  ratio, with a reference group.

- time:

  Time of the survival probability, required for `measure = "surv"`.

- a.ref, b.ref:

  Parameters of the posterior distribution of the reference group, or
  `NULL` for a one-sample probability.

- higher.better:

  Logical: `TRUE` if higher rates or survival probabilities (longer
  times) are favorable.

- n.nodes:

  Number of Gauss-Legendre nodes for the probability of a difference.

## Value

Numeric vector of posterior probabilities. `a`, `b`, `target`, `time`,
`a.ref` and `b.ref` are recycled to a common length.

## Details

The posterior distributions are given by their parameters.

- `measure = "rate"`: the rate `p` has a beta posterior with shape
  parameters `a` and `b`, for example `a = a0 + x` and `b = b0 + n - x`
  for `x` responders among `n` patients and a `Beta(a0, b0)` prior.

- `measure = "surv"`: the event times are exponential with hazard
  `lambda`, which has a gamma posterior with shape `a` and rate `b`, for
  example `a = a0 + d` and `b = b0 + T` for `d` events and total
  follow-up time `T` and a `Gamma(a0, b0)` prior. The parameter is the
  survival probability `S(time) = exp(-lambda * time)`.

- `measure = "hr"`: the hazard ratio `lambda / lambda_ref` of two such
  exponential models; a reference group is required.

Without a reference group (`a.ref` and `b.ref` are `NULL`), the result
is `P(p >= target)` or `P(S(time) >= target)` when
`higher.better = TRUE`, and `P(p <= target)` or `P(S(time) <= target)`
otherwise.

With a reference group, the result is `P(theta - theta_ref >= target)`
when `higher.better = TRUE` and `P(theta - theta_ref <= target)`
otherwise, where `theta` is the rate or the survival probability and
`target` is a margin in `(-1, 1)`. For the hazard ratio, the result is
`P(lambda / lambda_ref <= target)` when `higher.better = TRUE` (longer
times are favorable) and `P(lambda / lambda_ref >= target)` otherwise.
The two posterior distributions are independent.

One-sample probabilities and the probability of the hazard ratio are
computed in closed form (beta, gamma and F distributions). The
probability of a difference is a one-dimensional integral computed with
an `n.nodes`-point Gauss-Legendre rule on the probability scale of one
of the two posterior distributions; with the default 200 nodes the
absolute error is of the order of `1e-6` or smaller.

## References

Chakraborty, S., Dubey, A. K., Kumar, A. and Chan, I. (2026). A
two-stage dose optimization framework for oncology drug development with
multiple efficacy and safety endpoints via an integrated benefit-risk
assessment. *Statistics in Biopharmaceutical Research*, published
online.
[doi:10.1080/19466315.2026.2668381](https://doi.org/10.1080/19466315.2026.2668381)

## See also

[`BenefitRisk`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/BenefitRisk.md)

## Examples

``` r
# P(ORR >= 0.3) with 18 responders among 40 patients and a Beta(0.5, 0.5) prior
PosteriorProb("rate", a = 0.5 + 18, b = 0.5 + 22, target = 0.3)
#> [1] 0.9780309

# P(S(6) >= 0.5) with 20 events in 300 months of follow-up
PosteriorProb("surv", a = 0.5 + 20, b = 300, target = 0.5, time = 6)
#> [1] 0.996266

# P(AE rate - AE rate of the reference <= 0.1)
PosteriorProb("rate", a = 0.5 + 12, b = 0.5 + 28, target = 0.1,
              a.ref = 0.5 + 8, b.ref = 0.5 + 32, higher.better = FALSE)
#> [1] 0.5094168

# P(HR <= 0.8)
PosteriorProb("hr", a = 0.5 + 20, b = 300, target = 0.8,
              a.ref = 0.5 + 25, b.ref = 280)
#> [1] 0.5893727
```
