# Benefit-risk scores and win statistics of simulated trials

For each simulated trial, computes the posterior benefit-risk score of
every cohort against target values and compares every other cohort with
a reference cohort by the difference of these scores, optionally by the
benefit-risk score relative to the reference cohort, and by generalized
pairwise comparisons. The results are summarized by
[`SelectionOC`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SelectionOC.md)
and
[`CalibrateThreshold`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/CalibrateThreshold.md).

## Usage

``` r
SimSelection(
  data,
  endpoints,
  criteria,
  reference,
  cohorts = NULL,
  criteria.ref = NULL,
  priority = NULL,
  threshold = NULL,
  scoring = c("gehan", "peron"),
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

- reference:

  Name of the reference cohort.

- cohorts:

  Names of the cohorts compared, including `reference`; by default all
  cohorts of `data` (in the order of the levels of a factor, otherwise
  in the order of appearance).

- criteria.ref:

  Optional data frame of the components of the benefit-risk score
  relative to the reference cohort.

- priority, threshold, scoring:

  Priority order, thresholds and scoring rule of the pairwise
  comparisons; see
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

A data frame of class `SimSelection` with one row per simulated trial
and cohort and an attribute `settings` with the reference cohort, the
scoring rule and the confidence level (see
[`SimSelection-methods`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection-methods.md)
for [`print()`](https://rdrr.io/r/base/print.html) and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html)). The
statistics that compare a cohort with the reference cohort are `NA` in
the rows of the reference cohort. With `scores = TRUE`, the posterior
probabilities of the components are added after the columns below, in
columns named `S:` (against target values) and `ref:` (relative to the
reference cohort) followed by the label of the component. The columns
are

- sim:

  The simulated trial.

- group:

  The cohort.

- is_reference:

  Whether the cohort is the reference cohort.

- br, adm:

  Benefit-risk score and admissibility against target values.

- br_diff:

  Difference of `br` from that of the reference cohort.

- br_ref, adm_ref:

  Benefit-risk score and admissibility relative to the reference cohort
  (only with `criteria.ref`).

- p_win, p_loss, p_tie, ntb, ntb_se, ntb_lower, wr, wo:

  Proportions of pairs won, lost and tied against the reference cohort,
  net treatment benefit with its standard error and lower confidence
  bound, win ratio and win odds.

## Details

The reference cohort is the one chosen when no other cohort is shown to
be better, for example the cohort of the standard combination. The
benefit-risk scores are computed as in
[`BenefitRisk`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/BenefitRisk.md),
with `criteria` for the scores against target values and `criteria.ref`
for the scores relative to the reference cohort. The win statistics of a
cohort are those of
[`WinStat`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/WinStat.md)
with the cohort as treatment and the reference cohort as control. Every
simulated trial must contain patients of every cohort.

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
res <- SimSelection(d, eps, crit, reference = "Cohort2", criteria.ref = crit_ref)
head(res)
#> 6 rows of results of 3 simulated trials
#> Cohorts: Cohort1, Cohort2 (reference)
#> Scoring rule of the pairwise comparisons: Gehan
#> 
#>  sim   group is_reference    br  adm br_diff br_ref adm_ref p_win p_loss
#>    1 Cohort1        FALSE 0.683 TRUE 0.05065  0.157    TRUE 0.605  0.378
#>    1 Cohort2         TRUE 0.632 TRUE      NA     NA      NA    NA     NA
#>    2 Cohort1        FALSE 0.904 TRUE 0.00158  0.447    TRUE 0.549  0.424
#>    2 Cohort2         TRUE 0.903 TRUE      NA     NA      NA    NA     NA
#>    3 Cohort1        FALSE 0.778 TRUE 0.19573  0.694    TRUE 0.534  0.461
#>    3 Cohort2         TRUE 0.582 TRUE      NA     NA      NA    NA     NA
#>    p_tie    ntb ntb_se ntb_lower   wr   wo
#>  0.01688 0.2269  0.125   -0.0269 1.60 1.59
#>       NA     NA     NA        NA   NA   NA
#>  0.02688 0.1256  0.127   -0.1269 1.30 1.29
#>       NA     NA     NA        NA   NA   NA
#>  0.00437 0.0731  0.130   -0.1805 1.16 1.16
#>       NA     NA     NA        NA   NA   NA
```
