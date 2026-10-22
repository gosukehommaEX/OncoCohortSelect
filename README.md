# OncoCohortSelect

<!-- badges: start -->
[![R-CMD-check](https://github.com/gosukehommaEX/OncoCohortSelect/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/gosukehommaEX/OncoCohortSelect/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://img.shields.io/badge/pkgdown-documentation-blue.svg)](https://gosukehommaEX.github.io/OncoCohortSelect/)
[![Codecov test coverage](https://codecov.io/gh/gosukehommaEX/OncoCohortSelect/graph/badge.svg)](https://app.codecov.io/gh/gosukehommaEX/OncoCohortSelect)
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
  time-to-event endpoints with the scoring rule of Gehan or of Péron et al.
  (2018): the net treatment benefit, the win ratio and the win odds, with
  standard errors from the U-statistic theory. Any number of endpoints, any
  priority order and thresholds for time-to-event endpoints can be used.
* **Simulation.** Correlated progression-free survival, overall survival and
  objective response are generated for each cohort with the
  [CorOncoEndpoints](https://github.com/gosukehommaEX/CorOncoEndpoints)
  package, an adverse event independent of them is added, and the data are cut
  at a calendar time of analysis. Two or more cohorts are compared with a
  reference cohort, and the decision rules are compared at a common
  probability of selecting a cohort that is not better than the reference.
* **Data of a completed trial** can use columns coded as in ADaM data sets,
  such as censoring indicators (`CNSR`) and the best overall response.

## Installation

OncoCohortSelect and the package it uses to simulate correlated endpoints,
[CorOncoEndpoints](https://github.com/gosukehommaEX/CorOncoEndpoints), are
installed from GitHub; neither is on CRAN.

```r
install.packages("remotes")
# CorOncoEndpoints, at the version used by OncoCohortSelect
remotes::install_github("gosukehommaEX/CorOncoEndpoints@35f731d6052ff31625c140af0018b2558142dfc3")
remotes::install_github("gosukehommaEX/OncoCohortSelect")
```

The second call alone also installs CorOncoEndpoints at this version, which is
fixed in the `Remotes` field of DESCRIPTION; the first call makes the
dependency explicit. CorOncoEndpoints contains C++ code and is built from
source, so Rtools is needed on Windows.

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
w <- WinStat(d, eps, treatment = "Cohort1", control = "Cohort2")
w
plot(w)

# censored pairs scored with the Kaplan-Meier estimates (Peron)
WinStat(d, eps, treatment = "Cohort1", control = "Cohort2", scoring = "peron")$ci
```

Columns coded as in ADaM data sets are named in `Endpoint()`:

```r
Endpoint("OS", "tte", time = "OSAVAL", censor = "OSCNSR")
Endpoint("ORR", "binary", var = "BOR", positive = c("CR", "PR"))
Endpoint("AE", "binary", var = "AEFL", positive = "Y", higher.better = FALSE)
```

## Functions

| Function | Purpose |
|---|---|
| `Endpoint()` | Define a binary or time-to-event endpoint |
| `PosteriorProb()` | Posterior probability that a rate, survival probability or hazard ratio is favorable |
| `BenefitRisk()` | Component probabilities, admissibility and composite benefit-risk score of cohorts |
| `WinStat()` | Net treatment benefit, win ratio and win odds of prioritized endpoints |
| `SimCohorts()` | Simulate cohorts with correlated PFS, OS and response and an adverse event |
| `SimSelection()` | Benefit-risk scores and win statistics of simulated trials, for two or more cohorts against a reference cohort |
| `SelectionOC()` | Probability that a decision rule selects each cohort |
| `CalibrateThreshold()` | Threshold of a decision rule for a given probability of selecting a cohort other than the reference |

The results of `BenefitRisk()`, `WinStat()`, `SimSelection()` and
`SelectionOC()` have `print()` and `plot()` methods.

## Verification

* `tests/testthat`: expected values computed independently in Python
  (`inst/validation/python`), the example of Section S.4 of the supplementary
  material of Chakraborty et al. (2026), hand calculations, and comparisons
  with the BuyseTest package (Gehan and Péron scoring rules).
* `inst/reproduce/reproduce_published.R`: reproduction of published numbers.
* `inst/validation/validate_posterior.R`: Monte Carlo check of the posterior
  probabilities.
* `inst/validation/validate_winstat.R`: comparison of the win statistics with
  BuyseTest on simulated trials, with the Gehan and Péron scoring rules.
* `inst/validation/validate_simcohorts.R`: Monte Carlo check of the simulated
  cohorts.

## Articles

* Getting started with OncoCohortSelect
* Posterior benefit-risk score
* Net benefit and win ratio
* Evaluating decision rules by simulation
* Analyzing a completed trial

## References

Buyse, M. (2010). Generalized pairwise comparisons of prioritized outcomes in
the two-sample problem. *Statistics in Medicine*, 29, 3245-3257.
https://doi.org/10.1002/sim.3923

Chakraborty, S., Dubey, A. K., Kumar, A. and Chan, I. (2026). A two-stage dose
optimization framework for oncology drug development with multiple efficacy
and safety endpoints via an integrated benefit-risk assessment. *Statistics in
Biopharmaceutical Research*, published online.
https://doi.org/10.1080/19466315.2026.2668381

Péron, J., Buyse, M., Ozenne, B., Roche, L. and Roy, P. (2018). An extension of
generalized pairwise comparisons for prioritized outcomes in the presence of
censoring. *Statistical Methods in Medical Research*, 27, 1230-1239.
https://doi.org/10.1177/0962280216658320

## License

MIT (see `LICENSE.md`).
