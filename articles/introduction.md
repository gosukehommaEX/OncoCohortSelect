# Getting started with OncoCohortSelect

``` r

library(OncoCohortSelect)
```

OncoCohortSelect compares single-arm cohorts with several efficacy and
safety endpoints, for example two combination regimens studied in
parallel cohorts of a phase 2 trial, by two approaches:

- a posterior benefit-risk score (Chakraborty et al., 2026), computed
  for each cohort against target values or for one cohort relative to
  another, and
- generalized pairwise comparisons of prioritized endpoints (Buyse,
  2010), which give the net treatment benefit, the win ratio and the win
  odds.

The same functions are used for the data of a completed trial and for
simulated trials. This vignette analyzes one simulated trial; the
vignette “Comparing selection rules by simulation” evaluates the two
approaches.

## Data

Each cohort is described by an `OncoArm` object of the CorOncoEndpoints
package, which generates progression-free survival (PFS), overall
survival (OS) and objective response with the association between them.
[`SimCohorts()`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimCohorts.md)
adds a binary adverse event, independent of the other endpoints, and
cuts the data at the calendar time of the analysis. Here 50 patients per
cohort are enrolled over 12 months and analyzed at month 24.

``` r

arms <- list(
  Cohort1 = CorOncoEndpoints::OncoArm(pfs.median = 8, orr = 0.45, resp.cor = 0.4,
                                      death.prop = 0.15, os.median = 18),
  Cohort2 = CorOncoEndpoints::OncoArm(pfs.median = 6, orr = 0.30, resp.cor = 0.4,
                                      death.prop = 0.15, os.median = 15))
d <- SimCohorts(nsim = 1, n = c(50, 50), arms = arms, ae.rate = c(0.35, 0.20),
                cutoff = 24, a.time = c(0, 12), seed = 1)
head(d)
#>   sim   group accrual_time   pfs_tte pfs_event    os_tte os_event response ae
#> 1   1 Cohort1     3.436951 20.563049         0 20.563049        0        1  0
#> 2   1 Cohort1    11.376369 10.103116         1 12.623631        0        0  1
#> 3   1 Cohort1     9.781919  1.476153         1  3.707829        1        0  0
#> 4   1 Cohort1     8.375189  5.596166         1  5.596166        1        0  0
#> 5   1 Cohort1    10.245421  3.599755         1 11.469013        1        0  1
#> 6   1 Cohort1    10.204578 10.252275         1 13.795422        0        1  1
```

The endpoints are defined by the columns that hold them and by their
favorable direction. Any number of endpoints can be defined.

``` r

eps <- list(
  Endpoint("OS", "tte", time = "os_tte", event = "os_event"),
  Endpoint("PFS", "tte", time = "pfs_tte", event = "pfs_event"),
  Endpoint("ORR", "binary", var = "response"),
  Endpoint("AE", "binary", var = "ae", higher.better = FALSE))
```

## Posterior benefit-risk score

Each row of the criteria defines a component: the posterior probability
that an endpoint is favorable. Response and adverse event rates have
beta priors (by default `Beta(0.5, 0.5)`); for PFS and OS the event
times are taken as exponential with a gamma prior of the hazard (by
default shape 0.5 and rate 0), and the parameter is the survival
probability at a given time. The composite score is the weighted
geometric mean of the components, and a cohort is admissible when every
component with a cutoff reaches it.

``` r

crit <- data.frame(endpoint = c("ORR", "PFS", "OS", "AE"),
                   target = c(0.30, 0.50, 0.60, 0.30),
                   time = c(NA, 6, 12, NA),
                   cutoff = c(0.50, 0.50, NA, 0.50))
br <- BenefitRisk(d, eps, crit)
br
#>     group       ORR    PFS_S6    OS_S12        AE admissible        BR selected
#> 1 Cohort1 0.9916396 0.8570022 0.5082659 0.3718876      FALSE 0.6330815    FALSE
#> 2 Cohort2 0.5082945 0.5815179 0.7130959 0.9956593       TRUE 0.6768373     TRUE
sel <- if (any(br$selected)) br$group[br$selected] else "none (no cohort is admissible)"
```

`ORR` is `P(ORR >= 0.3)`, `PFS_S6` is `P(S(6) >= 0.5)` for PFS, `OS_S12`
is `P(S(12) >= 0.6)` for OS and `AE` is `P(AE rate <= 0.3)`. The
admissible cohort with the highest score is selected; here it is
Cohort2. Because each component is the probability of exceeding a fixed
target, the components of a cohort that clearly exceeds all targets are
close to 1, and the score then separates cohorts little.

With a reference cohort, each component is the probability of a
difference from the reference: a margin for a rate or a survival
probability, or a bound for the hazard ratio.

``` r

crit_ref <- data.frame(endpoint = c("ORR", "PFS", "OS", "AE"),
                       measure = c("rate", "hr", "hr", "rate"),
                       target = c(0.10, 0.80, 0.90, 0.10))
BenefitRisk(d, eps, crit_ref, reference = "Cohort2")
#>     group reference       ORR    PFS_HR    OS_HR        AE admissible        BR
#> 1 Cohort1   Cohort2 0.7282938 0.3353649 0.224306 0.1728606       TRUE 0.3119538
```

Here `ORR` is `P(ORR1 - ORR2 >= 0.1)`, `PFS_HR` and `OS_HR` are the
probabilities that the hazard ratios of Cohort1 versus Cohort2 are at
most 0.8 and 0.9, and `AE` is `P(AE1 - AE2 <= 0.1)`.

## Win statistics

Every patient of Cohort1 is compared with every patient of Cohort2,
first on OS, then on PFS (both by the rule of Gehan), then on response
and finally on the adverse event.

``` r

w <- WinStat(d, eps, treatment = "Cohort1", control = "Cohort2")
w$ci
#>   statistic   estimate        se      lower     upper
#> 1       NTB -0.0192000 0.1178581 -0.2451867 0.2087657
#> 2        WR  0.9615385 0.2315451  0.5997792 1.5414942
#> 3        WO  0.9623234 0.2269189  0.6061848 1.5276964
w$by.endpoint
#>   priority endpoint threshold    win   loss undecided
#> 1        1       OS         0 0.3196 0.4096    0.2708
#> 2        2      PFS         0 0.1568 0.0840    0.0300
#> 3        3      ORR         0 0.0036 0.0032    0.0232
#> 4        4       AE         0 0.0000 0.0024    0.0208
```

Of the 2500 pairs, 48% are won and 49.9% lost by the patient of Cohort1,
which gives a win ratio of 0.96. `by.endpoint` shows how many pairs each
endpoint decides: an endpoint lower in the priority order can only
decide the pairs left undecided by the endpoints above it. The priority
order and thresholds for the time-to-event endpoints are set by
`priority` and `threshold`:

``` r

WinStat(d, eps, treatment = "Cohort1", control = "Cohort2",
        priority = c("ORR", "PFS", "AE", "OS"), threshold = c(0, 2, 0, 0))$by.endpoint
#>   priority endpoint threshold    win   loss undecided
#> 1        1      ORR         0 0.3220 0.1620     0.516
#> 2        2      PFS         2 0.1432 0.2088     0.164
#> 3        3       AE         0 0.0160 0.0500     0.098
#> 4        4       OS         0 0.0180 0.0500     0.030
```

## References

Buyse, M. (2010). Generalized pairwise comparisons of prioritized
outcomes in the two-sample problem. *Statistics in Medicine*, 29,
3245-3257. <https://doi.org/10.1002/sim.3923>

Chakraborty, S., Dubey, A. K., Kumar, A. and Chan, I. (2026). A
two-stage dose optimization framework for oncology drug development with
multiple efficacy and safety endpoints via an integrated benefit-risk
assessment. *Statistics in Biopharmaceutical Research*, published
online. <https://doi.org/10.1080/19466315.2026.2668381>
