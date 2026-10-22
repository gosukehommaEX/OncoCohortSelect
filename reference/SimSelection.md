# Benefit-risk scores and win statistics of simulated trials

For each simulated trial, compares a treatment cohort with a control
cohort by the posterior benefit-risk score against target values (both
cohorts), optionally by the benefit-risk score of the treatment cohort
relative to the control cohort, and by generalized pairwise comparisons.
The results are summarized by
[`SelectionOC`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SelectionOC.md)
and
[`CalibrateThreshold`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/CalibrateThreshold.md).

## Usage

``` r
SimSelection(
  data,
  endpoints,
  criteria,
  treatment,
  control,
  criteria.ref = NULL,
  priority = NULL,
  threshold = NULL,
  group = "group",
  sim = "sim",
  conf.level = 0.95,
  n.nodes = 200,
  scores = FALSE
)
```

## Arguments

- data:

  Patient-level data of many simulated trials, for example from
  [`SimCohorts`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimCohorts.md).

- endpoints:

  An
  [`Endpoint`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/Endpoint.md)
  object or a list of them.

- criteria:

  Data frame of the components of the benefit-risk score against target
  values; see
  [`BenefitRisk`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/BenefitRisk.md).

- treatment, control:

  Names of the two cohorts compared.

- criteria.ref:

  Optional data frame of the components of the benefit-risk score of
  `treatment` relative to `control`.

- priority, threshold:

  Priority order and thresholds of the pairwise comparisons; see
  [`WinStat`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/WinStat.md).

- group, sim:

  Names of the columns of `data` with the cohort and the simulated
  trial.

- conf.level:

  Confidence level of the lower bound of the net treatment benefit.

- n.nodes:

  Number of Gauss-Legendre nodes for probabilities of differences.

- scores:

  Logical: if `TRUE`, the posterior probabilities of the components are
  added to the output.

## Value

A data frame with one row per simulated trial. With `scores = TRUE`, the
posterior probabilities of the components are added after the columns
below, in columns named `trt:`, `ctl:` and `ref:` followed by the label
of the component. The columns are

- sim:

  The simulated trial.

- br_trt, br_ctl:

  Benefit-risk scores against target values.

- adm_trt, adm_ctl:

  Admissibility against target values.

- br_diff:

  `br_trt - br_ctl`.

- br_ref, adm_ref:

  Benefit-risk score and admissibility of the treatment cohort relative
  to the control cohort (only with `criteria.ref`).

- p_win, p_loss, p_tie, ntb, ntb_se, ntb_lower, wr, wo:

  Proportions of pairs won, lost and tied, net treatment benefit with
  its standard error and lower confidence bound, win ratio and win odds.

## Details

The benefit-risk scores are computed as in
[`BenefitRisk`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/BenefitRisk.md),
with `criteria` for the scores against target values and `criteria.ref`
for the score relative to the control cohort. The win statistics are
computed as in
[`WinStat`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/WinStat.md).
Every simulated trial must contain patients of both cohorts.

## See also

[`SelectionOC`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SelectionOC.md),
[`CalibrateThreshold`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/CalibrateThreshold.md)

## Examples

``` r
arms <- list(
  Cohort1 = CorOncoEndpoints::OncoArm(pfs.median = 8, orr = 0.45, resp.cor = 0.4,
                                      death.prop = 0.15, os.median = 18),
  Cohort2 = CorOncoEndpoints::OncoArm(pfs.median = 6, orr = 0.30, resp.cor = 0.4,
                                      death.prop = 0.15, os.median = 15))
d <- SimCohorts(nsim = 20, n = c(40, 40), arms = arms, ae.rate = c(0.35, 0.20),
                cutoff = 24, a.time = c(0, 12), seed = 1)
eps <- list(Endpoint("OS", "tte", time = "os_tte", event = "os_event"),
            Endpoint("PFS", "tte", time = "pfs_tte", event = "pfs_event"),
            Endpoint("ORR", "binary", var = "response"),
            Endpoint("AE", "binary", var = "ae", higher.better = FALSE))
crit <- data.frame(endpoint = c("ORR", "PFS", "AE"), target = c(0.3, 0.5, 0.3),
                   time = c(NA, 6, NA))
crit_ref <- data.frame(endpoint = c("ORR", "PFS", "AE"),
                       measure = c("rate", "hr", "rate"),
                       target = c(0.1, 0.8, 0.1))
res <- SimSelection(d, eps, crit, treatment = "Cohort1", control = "Cohort2",
                    criteria.ref = crit_ref)
head(res)
#>   sim    br_trt    br_ctl adm_trt adm_ctl      br_diff    br_ref adm_ref
#> 1   1 0.6831450 0.6324917    TRUE    TRUE  0.050653320 0.1567579    TRUE
#> 2   2 0.9042010 0.9026234    TRUE    TRUE  0.001577663 0.4472643    TRUE
#> 3   3 0.7779846 0.5822519    TRUE    TRUE  0.195732696 0.6936594    TRUE
#> 4   4 0.1008843 0.7411899    TRUE    TRUE -0.640305644 0.1004474    TRUE
#> 5   5 0.6975435 0.4839362    TRUE    TRUE  0.213607320 0.5707428    TRUE
#> 6   6 0.5270903 0.5976262    TRUE    TRUE -0.070535818 0.4452342    TRUE
#>      p_win   p_loss    p_tie      ntb    ntb_se   ntb_lower       wr       wo
#> 1 0.605000 0.378125 0.016875 0.226875 0.1247553 -0.02688578 1.600000 1.586904
#> 2 0.549375 0.423750 0.026875 0.125625 0.1274969 -0.12691586 1.296460 1.287348
#> 3 0.534375 0.461250 0.004375 0.073125 0.1298129 -0.18053982 1.158537 1.157788
#> 4 0.519375 0.465625 0.015000 0.053750 0.1294372 -0.19797630 1.115436 1.113606
#> 5 0.582500 0.400625 0.016875 0.181875 0.1258315 -0.07102143 1.453978 1.444614
#> 6 0.536250 0.449375 0.014375 0.086875 0.1284614 -0.16507538 1.193324 1.190281
```
