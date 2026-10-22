# Posterior benefit-risk score of cohorts

Computes, for each cohort, the posterior probabilities that its
endpoints are favorable, the admissibility of the cohort and the
composite benefit-risk score of Chakraborty et al. (2026). Without a
reference cohort each cohort is assessed against target values; with a
reference cohort each other cohort is assessed by its difference from
the reference.

## Usage

``` r
BenefitRisk(
  data,
  endpoints,
  criteria,
  group = "group",
  reference = NULL,
  n.nodes = 200
)
```

## Arguments

- data:

  Patient-level data frame with one row per patient.

- endpoints:

  An
  [`Endpoint`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/Endpoint.md)
  object or a list of them.

- criteria:

  Data frame of the components; see Details.

- group:

  Name of the column of `data` with the cohort.

- reference:

  `NULL` for scores against target values, or the cohort used as the
  reference.

- n.nodes:

  Number of Gauss-Legendre nodes for probabilities of differences.

## Value

A data frame of class `BenefitRisk` with one row per cohort (other than
the reference) and columns `group`, `reference` (with a reference
cohort), one column per component with its posterior probability,
`admissible`, `BR` and, without a reference cohort, `selected`. The
attribute `components` holds the definition, weight and cutoff of each
component, and the attribute `reference` the reference cohort (if any).
See
[`BenefitRisk-methods`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/BenefitRisk-methods.md)
for [`print()`](https://rdrr.io/r/base/print.html) and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Details

**Components.** Each row of `criteria` defines a component `S_k`: the
posterior probability that the parameter of an endpoint is favorable
(see
[`PosteriorProb`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/PosteriorProb.md)).
For a binary endpoint the parameter is the rate, with a beta prior and a
binomial likelihood. For a time-to-event endpoint the event times are
taken as exponential, with a gamma prior of the hazard; the parameter is
the survival probability at `time` (`measure = "surv"`) or, with a
reference cohort, the hazard ratio (`measure = "hr"`). Without a
reference cohort, a component is `P(parameter >= target)` for a
favorable direction `higher.better = TRUE` of the endpoint and
`P(parameter <= target)` otherwise; with a reference cohort, it is the
probability that the difference from the reference is at least `target`
(or at most `target`), or that the hazard ratio is at most `target`. A
median can be assessed through the survival probability at the target
median with `target = 0.5`.

**Columns of `criteria`.**

- `endpoint` (required): the name of an endpoint in `endpoints`. An
  endpoint can appear in several components, for example the survival
  probabilities at two times.

- `target` (required): the target value or margin.

- `measure`: `"rate"` (binary endpoints), `"surv"` or `"hr"`
  (time-to-event endpoints); by default `"rate"` and `"surv"`.

- `time`: the time of the survival probability.

- `weight`: the exponent of the component in the composite score; by
  default `1 / K` for `K` components.

- `cutoff`: the admissibility cutoff of the component, or `NA` for none.

- `prior.a`, `prior.b`: the parameters of the prior: beta shape
  parameters (default 0.5 and 0.5), or gamma shape and rate of the
  hazard (default 0.5 and 0).

- `label`: the name of the component in the output; by default the
  endpoint name, followed by `_S` and the time for survival
  probabilities (for example `PFS_S6`) and by `_HR` for hazard ratios.

**Composite score and admissibility.** The benefit-risk score is
`BR = prod(S_k ^ weight_k)`. With equal weights summing to 1 it is the
geometric mean of the components. The score of Chakraborty et al.
(2026), the geometric mean of the efficacy components times the
geometric mean of the safety components, is obtained with weights
`1 / K_efficacy` and `1 / K_safety`. A cohort is admissible when every
component with a cutoff satisfies `S_k >= cutoff_k`; the cutoff of a
safety component of the form `P(Delta >= t) < p` in Chakraborty et al.
(2026) is `1 - p`. Without a reference cohort, the admissible cohort
with the highest score is marked as selected.

## References

Chakraborty, S., Dubey, A. K., Kumar, A. and Chan, I. (2026). A
two-stage dose optimization framework for oncology drug development with
multiple efficacy and safety endpoints via an integrated benefit-risk
assessment. *Statistics in Biopharmaceutical Research*, published
online.
[doi:10.1080/19466315.2026.2668381](https://doi.org/10.1080/19466315.2026.2668381)

## See also

[`PosteriorProb`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/PosteriorProb.md),
[`WinStat`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/WinStat.md),
[`SimSelection`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection.md)

## Examples

``` r
set.seed(1)
d <- data.frame(group = rep(c("Cohort1", "Cohort2"), each = 40),
                pfs_tte = rexp(80, log(2) / rep(c(8, 6), each = 40)),
                pfs_event = 1,
                response = rbinom(80, 1, rep(c(0.45, 0.30), each = 40)),
                ae = rbinom(80, 1, rep(c(0.35, 0.20), each = 40)))
eps <- list(Endpoint("PFS", "tte", time = "pfs_tte", event = "pfs_event"),
            Endpoint("ORR", "binary", var = "response"),
            Endpoint("AE", "binary", var = "ae", higher.better = FALSE))

# against target values
crit <- data.frame(endpoint = c("ORR", "PFS", "AE"), target = c(0.3, 0.5, 0.3),
                   time = c(NA, 6, NA), cutoff = c(0.5, 0.5, 0.5))
BenefitRisk(d, eps, crit)
#> Posterior benefit-risk scores against target values
#> 
#>  component definition     weight cutoff
#>  ORR       P(rate >= 0.3) 0.333  0.5   
#>  PFS_S6    P(S(6) >= 0.5) 0.333  0.5   
#>  AE        P(rate <= 0.3) 0.333  0.5   
#> 
#>    group   ORR PFS_S6    AE admissible    BR selected
#>  Cohort1 0.996  0.955 0.627       TRUE 0.842     TRUE
#>  Cohort2 0.509  0.869 0.995       TRUE 0.761    FALSE
#> 
#> Selected: Cohort1

# Cohort1 relative to Cohort2
crit_ref <- data.frame(endpoint = c("ORR", "PFS", "AE"),
                       measure = c("rate", "hr", "rate"),
                       target = c(0.1, 0.8, 0.1))
BenefitRisk(d, eps, crit_ref, reference = "Cohort2")
#> Posterior benefit-risk scores relative to Cohort2
#> 
#>  component definition                weight cutoff
#>  ORR       P(rate - rate_ref >= 0.1) 0.333        
#>  PFS_HR    P(HR <= 0.8)              0.333        
#>  AE        P(rate - rate_ref <= 0.1) 0.333        
#> 
#>    group reference   ORR PFS_HR    AE admissible    BR
#>  Cohort1   Cohort2 0.817  0.266 0.296       TRUE 0.401
```
