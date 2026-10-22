# Simulate single-arm cohorts with correlated endpoints and an adverse event

Generates patient-level data of several single-arm cohorts for many
simulated trials: progression-free survival (PFS), overall survival (OS)
and objective response, correlated within a patient, from the
`CorOncoEndpoints` package, and a binary adverse event that is
independent of the other endpoints. The data can be cut at a common
calendar time of analysis.

## Usage

``` r
SimCohorts(
  nsim,
  n,
  arms,
  ae.rate,
  cutoff = NULL,
  a.time = NULL,
  a.rate = NULL,
  a.prop = NULL,
  d.hazard = 0,
  seed = NULL
)
```

## Arguments

- nsim:

  Number of simulated trials.

- n:

  Integer vector of cohort sizes, one per cohort.

- arms:

  A list of `OncoArm` objects, one per cohort (or a single object). The
  names of the list are the cohort labels; unnamed cohorts are labeled
  `"Cohort1"`, `"Cohort2"`, and so on.

- ae.rate:

  Numeric vector with the probability of the adverse event in each
  cohort.

- cutoff:

  Calendar time of the analysis, or `NULL` for no cutoff.

- a.time, a.rate, a.prop:

  Accrual of each cohort, passed to
  [`rOncoEndpoints`](https://gosukehommaEX.github.io/CorOncoEndpoints/reference/rOncoEndpoints.html):
  `NULL`, a numeric vector used for every cohort, or a list with one
  vector per cohort.

- d.hazard:

  Hazard of an exponential dropout time, a scalar or one value per
  cohort.

- seed:

  Optional integer seed.

## Value

A data frame with one row per patient, ordered by `sim` and cohort, with
columns `sim`, `group`, `accrual_time`, `pfs_tte`, `pfs_event`,
`os_tte`, `os_event`, `response` (observed by the cutoff when `cutoff`
is given) and `ae`.

## Details

Each cohort is described by an `OncoArm` object of the
`CorOncoEndpoints` package (see
[`OncoArm`](https://gosukehommaEX.github.io/CorOncoEndpoints/reference/OncoArm.html)),
which specifies the PFS median, the response rate, the association
between PFS and response and the OS model. The cohorts are generated
independently by
[`rOncoEndpoints`](https://gosukehommaEX.github.io/CorOncoEndpoints/reference/rOncoEndpoints.html),
one call per cohort, so that each cohort can have its own accrual and
dropout. With `seed`, cohort `j` uses stream `j` of the random number
generator seeded with `seed`, and the results are reproducible.

The adverse event of each patient is a Bernoulli variable with
probability `ae.rate` of the cohort, independent of PFS, OS and
response, and is taken as known at the analysis for every enrolled
patient.

With `cutoff`, the data are restricted to patients enrolled before the
calendar time `cutoff` (on the time scale of `a.time`, which starts at
0), and PFS and OS are censored at the cutoff by
[`CutoffData`](https://gosukehommaEX.github.io/CorOncoEndpoints/reference/CutoffData.html);
a response counts only if it was observed before the cutoff. Accrual
intervals that start later than 0 (for example
`a.time = list(c(0, 12), c(6, 18))`) describe cohorts enrolled at
different times.

## See also

[`SimSelection`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection.md)

## Examples

``` r
arms <- list(
  Cohort1 = CorOncoEndpoints::OncoArm(pfs.median = 8, orr = 0.45, resp.cor = 0.4,
                                      death.prop = 0.15, os.median = 18),
  Cohort2 = CorOncoEndpoints::OncoArm(pfs.median = 6, orr = 0.30, resp.cor = 0.4,
                                      death.prop = 0.15, os.median = 15))
d <- SimCohorts(nsim = 2, n = c(30, 30), arms = arms, ae.rate = c(0.35, 0.20),
                cutoff = 24, a.time = c(0, 12), seed = 1)
head(d)
#>   sim   group accrual_time   pfs_tte pfs_event    os_tte os_event response ae
#> 1   1 Cohort1    4.4648115 19.535189         0 19.535189        0        1  1
#> 2   1 Cohort1    9.9596607 10.103116         1 10.103116        1        1  1
#> 3   1 Cohort1    5.9214897  1.476153         1  4.644088        1        0  0
#> 4   1 Cohort1   11.8327362  5.596166         1  5.596166        1        1  1
#> 5   1 Cohort1    6.0778319  3.599755         1  3.599755        1        0  0
#> 6   1 Cohort1    0.5534634 10.252275         1 11.920372        1        1  0
table(d$sim, d$group)
#>    
#>     Cohort1 Cohort2
#>   1      30      30
#>   2      30      30
```
