# Analyzing a completed trial

``` r

library(OncoCohortSelect)
```

This article analyzes the data of a completed trial with three
single-arm cohorts, with column names in the style of ADaM data sets.
The data are fictitious and are installed with the package.

## Data

The file has one row per patient: the cohort (`TRT01P`), the overall and
progression-free survival times in months (`OSAVAL`, `PFSAVAL`) with
their censoring indicators (`OSCNSR`, `PFSCNSR`; 0 for an event and 1
for a censored time, as in ADaM), the best overall response (`BOR`) and
a flag for an adverse event of interest (`AEFL`, `"Y"` or blank).

``` r

path <- system.file("extdata", "example_trial.csv", package = "OncoCohortSelect")
adsl <- read.csv(path, stringsAsFactors = FALSE)
head(adsl)
#>   USUBJID   TRT01P OSAVAL OSCNSR PFSAVAL PFSCNSR BOR AEFL
#> 1  C1-001 Cohort 1  20.60      1   20.60       1  PR     
#> 2  C1-002 Cohort 1  22.88      1   10.77       0  PR     
#> 3  C1-003 Cohort 1  20.43      1   19.64       0  PR     
#> 4  C1-004 Cohort 1  11.87      0   11.87       0  PR     
#> 5  C1-005 Cohort 1  23.16      1   16.84       0  SD    Y
#> 6  C1-006 Cohort 1  12.31      1    2.98       0  SD
table(adsl$TRT01P, adsl$BOR)
#>           
#>            CR NE PD PR SD
#>   Cohort 1  1  1  7 13 18
#>   Cohort 2  3  0  6 12 19
#>   Cohort 3  5  0  8 17 10
table(adsl$TRT01P, adsl$AEFL == "Y")
#>           
#>            FALSE TRUE
#>   Cohort 1    31    9
#>   Cohort 2    31    9
#>   Cohort 3    17   23
```

## Endpoints

[`Endpoint()`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/Endpoint.md)
names the columns of each endpoint. For a time-to-event endpoint,
`censor` gives a censoring indicator coded as in ADaM (0 for an event,
any other value for a censored time) and `event` an event indicator (1
for an event). For a binary endpoint, `positive` lists the values that
count as 1, here a complete or partial response and the flag `"Y"`.

``` r

eps <- list(
  Endpoint("OS", "tte", time = "OSAVAL", censor = "OSCNSR"),
  Endpoint("PFS", "tte", time = "PFSAVAL", censor = "PFSCNSR"),
  Endpoint("ORR", "binary", var = "BOR", positive = c("CR", "PR")),
  Endpoint("AE", "binary", var = "AEFL", positive = "Y", higher.better = FALSE))
```

In ADaM, time-to-event data are usually in a separate data set with one
row per patient and parameter.
[`reshape()`](https://rdrr.io/r/stats/reshape.html) puts the parameters
side by side, and [`merge()`](https://rdrr.io/r/base/merge.html) adds
them to the data of the patients:

``` r

adtte <- data.frame(USUBJID = c("01", "01", "02", "02"),
                    PARAMCD = c("OS", "PFS", "OS", "PFS"),
                    AVAL = c(10.2, 5.1, 8.4, 8.4), CNSR = c(1, 0, 0, 0))
reshape(adtte, idvar = "USUBJID", timevar = "PARAMCD", direction = "wide")
#>   USUBJID AVAL.OS CNSR.OS AVAL.PFS CNSR.PFS
#> 1      01    10.2       1      5.1        0
#> 3      02     8.4       0      8.4        0
```

The columns `AVAL.OS` and `CNSR.OS` are then given to
[`Endpoint()`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/Endpoint.md).

## Benefit-risk scores

Against target values, with the criteria of the article *Evaluating
decision rules by simulation*:

``` r

crit <- data.frame(endpoint = c("ORR", "PFS", "OS", "AE"),
                   target = c(0.30, 0.50, 0.60, 0.40), time = c(NA, 6, 12, NA),
                   weight = c(1 / 3, 1 / 3, 1 / 3, 1), cutoff = c(NA, NA, NA, 0.8))
br <- BenefitRisk(adsl, eps, crit, group = "TRT01P")
br
#>      group       ORR    PFS_S6    OS_S12         AE admissible          BR
#> 1 Cohort 1 0.7585508 0.2487189 0.2241496 0.99011904       TRUE 0.344956673
#> 2 Cohort 2 0.8495470 0.9993728 0.9577358 0.99011904       TRUE 0.924146786
#> 3 Cohort 3 0.9995100 0.8494408 0.5243060 0.01270498      FALSE 0.009700831
#>   selected
#> 1    FALSE
#> 2     TRUE
#> 3    FALSE
```

Relative to Cohort 1, the reference regimen:

``` r

crit_ref <- data.frame(endpoint = c("ORR", "PFS", "OS", "AE"),
                       measure = c("rate", "hr", "hr", "rate"),
                       target = c(0.10, 0.80, 0.90, 0.10),
                       weight = c(1 / 3, 1 / 3, 1 / 3, 1), cutoff = c(NA, NA, NA, 0.8))
br_ref <- BenefitRisk(adsl, eps, crit_ref, group = "TRT01P", reference = "Cohort 1")
br_ref
#>      group reference       ORR    PFS_HR     OS_HR         AE admissible
#> 1 Cohort 2  Cohort 1 0.2371944 0.9642481 0.9251714 0.86211847       TRUE
#> 2 Cohort 3  Cohort 1 0.8135225 0.6166791 0.5885187 0.01030468      FALSE
#>            BR
#> 1 0.513734506
#> 2 0.006861683
```

## Win statistics

Each new cohort is compared with Cohort 1, with priority OS, PFS,
response and adverse event.

``` r

w2 <- WinStat(adsl, eps, treatment = "Cohort 2", control = "Cohort 1", group = "TRT01P")
w3 <- WinStat(adsl, eps, treatment = "Cohort 3", control = "Cohort 1", group = "TRT01P")
w2$ci
#>   statistic estimate        se     lower     upper
#> 1       NTB 0.331875 0.1176162 0.0856671 0.5398828
#> 2        WR 2.035088 0.5536582 1.1940114 3.4686286
#> 3        WO 1.993452 0.5269650 1.1873871 3.3467183
w3$ci
#>   statistic estimate        se       lower     upper
#> 1       NTB 0.167500 0.1252666 -0.08331817 0.3983604
#> 2        WR 1.407295 0.3664531  0.84476537 2.3444128
#> 3        WO 1.402402 0.3614904  0.84617968 2.3242493
```

The net treatment benefit against Cohort 1 is 0.33 for Cohort 2 and 0.17
for Cohort 3. With the scoring rule of Péron, censored pairs are scored
with the Kaplan-Meier estimates:

``` r

rbind(
  "Cohort 2" = WinStat(adsl, eps, treatment = "Cohort 2", control = "Cohort 1",
                       group = "TRT01P", scoring = "peron")$estimate,
  "Cohort 3" = WinStat(adsl, eps, treatment = "Cohort 3", control = "Cohort 1",
                       group = "TRT01P", scoring = "peron")$estimate)
#>              p_win    p_loss       p_tie       ntb       wr       wo
#> Cohort 2 0.6273485 0.3676415 0.005010019 0.2597070 1.706414 1.701633
#> Cohort 3 0.5740167 0.4206718 0.005311524 0.1533449 1.364524 1.362237
```

## Applying a decision rule

The decision rule and its threshold are fixed when the trial is
designed, for example with
[`CalibrateThreshold()`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/CalibrateThreshold.md)
as in the article *Evaluating decision rules by simulation*.
[`SimSelection()`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection.md)
computes all the statistics of a completed trial when the data are
treated as one simulated trial, and
[`SelectionOC()`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SelectionOC.md)
then gives a probability of 1 to the cohort that the rule selects. The
thresholds below are for illustration only.

``` r

adsl$sim <- 1
res <- SimSelection(adsl, eps, crit, reference = "Cohort 1", criteria.ref = crit_ref,
                    group = "TRT01P")
res[, c("group", "br", "adm", "br_diff", "br_ref", "adm_ref", "ntb", "wr")]
#>      group          br   adm    br_diff      br_ref adm_ref      ntb       wr
#> 1 Cohort 1 0.344956673  TRUE         NA          NA      NA       NA       NA
#> 2 Cohort 2 0.924146786  TRUE  0.5791901 0.513734506    TRUE 0.331875 2.035088
#> 3 Cohort 3 0.009700831 FALSE -0.3352558 0.006861683   FALSE 0.167500 1.407295
rules <- data.frame(statistic = c("br_diff", "br_ref", "ntb", "wr"),
                    threshold = c(0.05, 0.5, 0.1, 1.5))
sel <- vapply(seq_len(nrow(rules)), function(i) {
  oc <- SelectionOC(res, rules$statistic[i], threshold = rules$threshold[i])
  oc$group[oc$p_select == 1]
}, character(1))
data.frame(rules, selected = sel)
#>   statistic threshold selected
#> 1   br_diff      0.05 Cohort 2
#> 2    br_ref      0.50 Cohort 2
#> 3       ntb      0.10 Cohort 2
#> 4        wr      1.50 Cohort 2
```

## Note

The data of this article are invented for illustration. They are
generated by the script `data-raw/make_example_trial.py` of the GitHub
repository of the package.
