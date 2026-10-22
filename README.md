# OncoCohortSelect

<!-- badges: start -->
[![R-CMD-check](https://github.com/gosukehommaEX/OncoCohortSelect/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/gosukehommaEX/OncoCohortSelect/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://img.shields.io/badge/pkgdown-documentation-blue.svg)](https://gosukehommaEX.github.io/OncoCohortSelect/)
<!-- badges: end -->

OncoCohortSelect selects one of several single-arm oncology cohorts with
multiple efficacy and safety endpoints for further development, and evaluates
the selection rules by simulation.

## Methods

* **Posterior benefit-risk score** (Chakraborty et al., 2026). Each component
  is the posterior probability that an endpoint is favorable: a response or
  adverse event rate (beta-binomial model), a survival probability at a given
  time or a hazard ratio (exponential model with a gamma prior of the hazard).
  The components are computed against target values for each cohort, or
  relative to a reference cohort, and combined by a weighted geometric mean;
  admissibility cutoffs can be set for each component.
* **Generalized pairwise comparisons** (Buyse, 2010) of prioritized binary and
  time-to-event endpoints with the scoring rule of Gehan: the net treatment
  benefit, the win ratio and the win odds, with standard errors from the
  U-statistic theory. Any number of endpoints, any priority order and
  thresholds for time-to-event endpoints can be used.
* **Simulation.** Correlated progression-free survival, overall survival and
  objective response are generated for each cohort with the
  [CorOncoEndpoints](https://github.com/gosukehommaEX/CorOncoEndpoints)
  package, an adverse event independent of them is added, and the data are cut
  at a calendar time of analysis. The decision rules are compared at a common
  probability of selecting a cohort that is not better.

## Installation

```r
# install.packages("remotes")
remotes::install_github("gosukehommaEX/OncoCohortSelect")
```

CorOncoEndpoints is installed from GitHub with it (the version is fixed in the
`Remotes` field of DESCRIPTION).

## Example

```r
library(OncoCohortSelect)

arms <- list(
  Cohort1 = CorOncoEndpoints::OncoArm(pfs.median = 8, orr = 0.45, resp.cor = 0.4,
                                      death.prop = 0.15, os.median = 18),
  Cohort2 = CorOncoEndpoints::OncoArm(pfs.median = 6, orr = 0.30, resp.cor = 0.4,
                                      death.prop = 0.15, os.median = 15))
d <- SimCohorts(nsim = 1, n = c(50, 50), arms = arms, ae.rate = c(0.35, 0.20),
                cutoff = 24, a.time = c(0, 12), seed = 1)

eps <- list(Endpoint("OS", "tte", time = "os_tte", event = "os_event"),
            Endpoint("PFS", "tte", time = "pfs_tte", event = "pfs_event"),
            Endpoint("ORR", "binary", var = "response"),
            Endpoint("AE", "binary", var = "ae", higher.better = FALSE))

# benefit-risk score against target values
crit <- data.frame(endpoint = c("ORR", "PFS", "OS", "AE"),
                   target = c(0.30, 0.50, 0.60, 0.30), time = c(NA, 6, 12, NA))
BenefitRisk(d, eps, crit)

# benefit-risk score of Cohort1 relative to Cohort2
crit_ref <- data.frame(endpoint = c("ORR", "PFS", "OS", "AE"),
                       measure = c("rate", "hr", "hr", "rate"),
                       target = c(0.10, 0.80, 0.90, 0.10))
BenefitRisk(d, eps, crit_ref, reference = "Cohort2")

# net treatment benefit, win ratio and win odds (priority OS, PFS, ORR, AE)
WinStat(d, eps, treatment = "Cohort1", control = "Cohort2")$ci
```

## Functions

| Function | Purpose |
|---|---|
| `Endpoint()` | Define a binary or time-to-event endpoint |
| `PosteriorProb()` | Posterior probability that a rate, survival probability or hazard ratio is favorable |
| `BenefitRisk()` | Component probabilities, admissibility and composite benefit-risk score of cohorts |
| `WinStat()` | Net treatment benefit, win ratio and win odds of prioritized endpoints |
| `SimCohorts()` | Simulate cohorts with correlated PFS, OS and response and an adverse event |
| `SimSelection()` | Benefit-risk scores and win statistics of simulated trials |
| `SelectionOC()` | Selection probabilities of a decision rule |
| `CalibrateThreshold()` | Threshold of a decision rule for a given false selection probability |

## Verification

* `tests/testthat`: expected values computed independently in Python
  (`inst/validation/python`), the example of Section S.4 of the supplementary
  material of Chakraborty et al. (2026), and comparisons with the BuyseTest
  package.
* `inst/reproduce/reproduce_published.R`: reproduction of published numbers.
* `inst/validation/validate_posterior.R`: Monte Carlo check of the posterior
  probabilities.
* `inst/validation/validate_winstat.R`: comparison of the win statistics with
  BuyseTest on simulated trials.
* `inst/validation/validate_simcohorts.R`: Monte Carlo check of the simulated
  cohorts.

## Vignettes

* Getting started with OncoCohortSelect
* Comparing selection rules by simulation

## References

Buyse, M. (2010). Generalized pairwise comparisons of prioritized outcomes in
the two-sample problem. *Statistics in Medicine*, 29, 3245-3257.
https://doi.org/10.1002/sim.3923

Chakraborty, S., Dubey, A. K., Kumar, A. and Chan, I. (2026). A two-stage dose
optimization framework for oncology drug development with multiple efficacy
and safety endpoints via an integrated benefit-risk assessment. *Statistics in
Biopharmaceutical Research*, published online.
https://doi.org/10.1080/19466315.2026.2668381

## License

MIT (see `LICENSE.md`).
