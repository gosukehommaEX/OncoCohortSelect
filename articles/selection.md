# Comparing selection rules by simulation

``` r

library(OncoCohortSelect)
```

Two single-arm cohorts, Cohort1 and Cohort2, are run in parallel, and
one of them is to be selected for further development. Cohort2 is the
default, and Cohort1 is selected only if the data favor it. This
vignette compares decision rules based on the posterior benefit-risk
score and on win statistics by their selection probabilities in
simulated trials.

## What makes a rule better

The scores of the two approaches are on different scales, so their raw
values cannot be compared. A fair comparison fixes, for every rule, the
probability of selecting Cohort1 when it is not better than Cohort2
(here, identical cohorts), and then compares the probabilities of
selecting Cohort1 when it is better. The truth must be defined before
the simulation and independently of the rules: by scenarios in which the
better cohort is clear (one cohort at least as good on every endpoint),
and, for trade-offs between efficacy and safety, by the choice the
clinical team would make for the true parameters.

## Scenarios

Each scenario gives the true parameters of the two cohorts: PFS and OS
medians, response rate and adverse event rate. The number of simulated
trials is kept small so that the vignette builds quickly; an evaluation
would use several thousand.

``` r

make_arm <- function(pfs, orr, os) {
  CorOncoEndpoints::OncoArm(pfs.median = pfs, orr = orr, resp.cor = 0.4,
                            death.prop = 0.15, os.median = os)
}
scenarios <- list(
  "Identical" = list(arms = list(Cohort1 = make_arm(6, 0.30, 15),
                                 Cohort2 = make_arm(6, 0.30, 15)), ae = c(0.20, 0.20)),
  "Cohort1 better" = list(arms = list(Cohort1 = make_arm(9, 0.50, 20),
                                      Cohort2 = make_arm(6, 0.30, 15)), ae = c(0.20, 0.20)),
  "Cohort1 better, more AE" = list(arms = list(Cohort1 = make_arm(9, 0.50, 20),
                                               Cohort2 = make_arm(6, 0.30, 15)),
                                   ae = c(0.40, 0.20)))
nsim <- 200
```

## Rules

The benefit-risk score against target values is computed for each
cohort, and Cohort1 is selected when its score exceeds that of Cohort2
by more than a threshold (`br_diff`). The score of Cohort1 relative to
Cohort2 selects Cohort1 when it exceeds a threshold (`br_ref`). The net
treatment benefit (`ntb`) and the win ratio (`wr`) of the pairwise
comparisons with priority OS, PFS, response and adverse event select
Cohort1 when they exceed a threshold.

``` r

eps <- list(
  Endpoint("OS", "tte", time = "os_tte", event = "os_event"),
  Endpoint("PFS", "tte", time = "pfs_tte", event = "pfs_event"),
  Endpoint("ORR", "binary", var = "response"),
  Endpoint("AE", "binary", var = "ae", higher.better = FALSE))
crit <- data.frame(endpoint = c("ORR", "PFS", "OS", "AE"),
                   target = c(0.30, 0.50, 0.60, 0.30), time = c(NA, 6, 12, NA))
crit_ref <- data.frame(endpoint = c("ORR", "PFS", "OS", "AE"),
                       measure = c("rate", "hr", "hr", "rate"),
                       target = c(0.10, 0.80, 0.90, 0.10))
```

Each scenario is simulated with 50 patients per cohort, enrolled over 12
months and analyzed at month 24.

``` r

res <- lapply(seq_along(scenarios), function(i) {
  sc <- scenarios[[i]]
  d <- SimCohorts(nsim = nsim, n = c(50, 50), arms = sc$arms, ae.rate = sc$ae,
                  cutoff = 24, a.time = c(0, 12), seed = i)
  SimSelection(d, eps, crit, treatment = "Cohort1", control = "Cohort2",
               criteria.ref = crit_ref)
})
names(res) <- names(scenarios)
head(res[["Cohort1 better"]][, c("br_trt", "br_ctl", "br_ref", "ntb", "wr")])
#>      br_trt     br_ctl    br_ref    ntb       wr
#> 1 0.9840167 0.28027139 0.9715141 0.3432 2.083333
#> 2 0.9974228 0.49534396 0.9086497 0.2996 1.884298
#> 3 0.6395187 0.20092152 0.6444149 0.1872 1.470352
#> 4 0.9667704 0.15834083 0.8852263 0.2728 1.761161
#> 5 0.9354467 0.85477364 0.7301443 0.1120 1.262911
#> 6 0.8789330 0.09728543 0.7966242 0.3912 2.323410
```

## Thresholds and selection probabilities

The thresholds are calibrated in the scenario with identical cohorts so
that Cohort1 is selected in at most 10% of the trials.

``` r

stats <- c("br_diff", "br_ref", "ntb", "wr")
thr <- do.call(rbind, lapply(stats, function(s) {
  CalibrateThreshold(res[["Identical"]], s, alpha = 0.10)
}))
thr
#>   statistic alpha threshold p_treatment
#> 1   br_diff   0.1 0.4294910         0.1
#> 2    br_ref   0.1 0.5583376         0.1
#> 3       ntb   0.1 0.1492000         0.1
#> 4        wr   0.1 1.3549001         0.1
tab <- sapply(names(res), function(sc) {
  vapply(seq_along(stats), function(i) {
    SelectionOC(res[[sc]], stats[i], threshold = thr$threshold[i])$p_treatment
  }, numeric(1))
})
rownames(tab) <- stats
knitr::kable(tab, digits = 2,
             caption = "Probability of selecting Cohort1 at the calibrated thresholds")
```

|         | Identical | Cohort1 better | Cohort1 better, more AE |
|:--------|----------:|---------------:|------------------------:|
| br_diff |       0.1 |           0.55 |                    0.07 |
| br_ref  |       0.1 |           0.84 |                    0.34 |
| ntb     |       0.1 |           0.66 |                    0.65 |
| wr      |       0.1 |           0.67 |                    0.65 |

Probability of selecting Cohort1 at the calibrated thresholds {.table}

In the scenario “Cohort1 better”, the rules select Cohort1 with
probabilities between 0.55 and 0.84. With more adverse events in
Cohort1, the probabilities range from 0.07 to 0.65; whether Cohort1
should be selected in that scenario is a clinical judgment that has to
be fixed before the rules are compared.

## Saturation of the score against target values

In the scenario “Cohort1 better”, the median scores against the target
values are 0.936 for Cohort1 and 0.441 for Cohort2. The score measures
how certainly a cohort exceeds the targets, not by how much. When both
cohorts clearly exceed the targets, both scores approach 1 and their
difference carries little information; the score relative to the other
cohort and the win statistics compare the cohorts directly.

``` r

summary(res[["Cohort1 better"]][, c("br_trt", "br_ctl")])
#>      br_trt           br_ctl       
#>  Min.   :0.3850   Min.   :0.03947  
#>  1st Qu.:0.8613   1st Qu.:0.27401  
#>  Median :0.9358   Median :0.44141  
#>  Mean   :0.9010   Mean   :0.45764  
#>  3rd Qu.:0.9731   3rd Qu.:0.64196  
#>  Max.   :0.9996   Max.   :0.91864
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
