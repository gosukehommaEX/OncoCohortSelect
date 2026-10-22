# Net treatment benefit, win ratio and win odds of prioritized endpoints

Compares every patient of one cohort (`treatment`) with every patient of
another cohort (`control`) on prioritized endpoints (generalized
pairwise comparisons, Buyse 2010) and computes the net treatment
benefit, the win ratio (Pocock et al. 2012) and the win odds (Brunner et
al. 2021) with standard errors and confidence intervals.

## Usage

``` r
WinStat(
  data,
  endpoints,
  treatment,
  control,
  group = "group",
  priority = NULL,
  threshold = NULL,
  scoring = c("gehan", "peron"),
  conf.level = 0.95
)
```

## Arguments

- data:

  Patient-level data frame with one row per patient.

- endpoints:

  An
  [`Endpoint`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/Endpoint.md)
  object or a list of them.

- treatment, control:

  Names of the two cohorts compared, values of the column `group`.

- group:

  Name of the column of `data` with the cohort.

- priority:

  Character vector of endpoint names in decreasing priority; by default
  the order of `endpoints`.

- threshold:

  Numeric vector of thresholds, one per element of `priority`: the
  minimal difference of times that decides a pair on a time-to-event
  endpoint (0 or `NA` for binary endpoints). By default 0 for every
  endpoint. The thresholds of an endpoint used more than once must
  decrease.

- scoring:

  Scoring rule of time-to-event endpoints: `"gehan"` or `"peron"`.

- conf.level:

  Confidence level of the intervals.

## Value

A list with elements

- estimate:

  Named vector with `p_win`, `p_loss`, `p_tie`, `ntb`, `wr` and `wo`.

- ci:

  Data frame with the estimate, standard error and confidence interval
  of the net treatment benefit (`NTB`), the win ratio (`WR`) and the win
  odds (`WO`).

- by.endpoint:

  Data frame with, for each priority level, the proportions of all pairs
  won and lost at that level and the proportion of pairs still undecided
  after it (with the Peron scoring rule, sums of probabilities divided
  by the number of pairs).

- n:

  Named vector with the numbers of treatment and control patients and of
  pairs.

## Details

A pair is compared on the endpoints in the order of `priority`. The
first endpoint that decides the pair determines a win or a loss of the
treatment patient; a pair that no endpoint decides is a tie. An endpoint
can appear more than once with decreasing thresholds, for example with a
large threshold first and a threshold of 0 later.

A binary endpoint decides a pair when the two patients have different
values; a pair with a missing value is undecided. With
`scoring = "gehan"`, a time-to-event endpoint is scored by the rule of
Gehan (1965): the pair is decided when the patient with the shorter
observed time has an event and the difference of the observed times is
at least the threshold. With a threshold of 0 the difference must be
positive, and a censored time equal to an event time counts as longer.
These rules agree with the Gehan scoring rule of the `BuyseTest`
package.

With `scoring = "peron"`, pairs with a censored time are scored by the
rule of Péron et al. (2018). The true time of a censored patient is
given the distribution of the Kaplan-Meier estimate of its cohort
conditional on survival beyond the censoring time, and the pair is won
with the probability that the treatment time is longer by at least the
threshold and lost with the probability that the control time is longer
by at least the threshold. The Kaplan-Meier estimate is not defined
after the largest observed time of a cohort; the probability beyond that
time counts only when the comparison holds wherever the true time lies,
so the two probabilities are lower bounds, and the rest of the pair goes
to the next endpoints. When an endpoint is used again with a smaller
threshold, the probabilities at its previous threshold are subtracted,
since a pair won at the larger threshold is also won at the smaller one,
and the weight of a pair is the product over the other endpoints of the
probability that the pair is still undecided. These rules agree with the
Peron scoring rule of the `BuyseTest` package, except that a difference
of times exactly equal to a positive threshold always counts as decided,
which can give small differences when times plus or minus the threshold
coincide with event times.

With `p_win`, `p_loss` and `p_tie` the proportions of pairs won, lost
and tied by the treatment patient, the net treatment benefit is
`p_win - p_loss`, the win ratio `p_win / p_loss` and the win odds
`(p_win + p_tie / 2) / (p_loss + p_tie / 2)`. Their standard errors are
computed from the first-order H-decomposition of the two-sample
U-statistics (Bebu and Lachin 2016), the standard errors of the win
ratio and the win odds by the delta method. With `scoring = "peron"` the
Kaplan-Meier estimates are treated as known, so the standard errors are
approximate and tend to be too small. The confidence interval of the net
treatment benefit is computed on the inverse hyperbolic tangent scale,
that of the win ratio on the log scale, and that of the win odds is the
interval of the net treatment benefit transformed by
`(1 + x) / (1 - x)`.

## References

Buyse, M. (2010). Generalized pairwise comparisons of prioritized
outcomes in the two-sample problem. *Statistics in Medicine*, 29,
3245-3257. [doi:10.1002/sim.3923](https://doi.org/10.1002/sim.3923)

Pocock, S. J., Ariti, C. A., Collier, T. J. and Wang, D. (2012). The win
ratio: a new approach to the analysis of composite endpoints in clinical
trials based on clinical priorities. *European Heart Journal*, 33,
176-182.
[doi:10.1093/eurheartj/ehr352](https://doi.org/10.1093/eurheartj/ehr352)

Brunner, E., Vandemeulebroecke, M. and Mütze, T. (2021). Win odds: an
adaptation of the win ratio to include ties. *Statistics in Medicine*,
40, 3367-3384. [doi:10.1002/sim.8967](https://doi.org/10.1002/sim.8967)

Bebu, I. and Lachin, J. M. (2016). Large sample inference for a win
ratio analysis of a composite outcome based on prioritized components.
*Biostatistics*, 17, 178-187.
[doi:10.1093/biostatistics/kxv032](https://doi.org/10.1093/biostatistics/kxv032)

Gehan, E. A. (1965). A generalized Wilcoxon test for comparing
arbitrarily singly-censored samples. *Biometrika*, 52, 203-223.
[doi:10.1093/biomet/52.1-2.203](https://doi.org/10.1093/biomet/52.1-2.203)

Péron, J., Buyse, M., Ozenne, B., Roche, L. and Roy, P. (2018). An
extension of generalized pairwise comparisons for prioritized outcomes
in the presence of censoring. *Statistical Methods in Medical Research*,
27, 1230-1239.
[doi:10.1177/0962280216658320](https://doi.org/10.1177/0962280216658320)

## See also

[`BenefitRisk`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/BenefitRisk.md),
[`SimSelection`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection.md)

## Examples

``` r
set.seed(1)
d <- data.frame(group = rep(c("Cohort1", "Cohort2"), each = 40),
                os_tte = rexp(80, log(2) / rep(c(18, 15), each = 40)),
                os_event = rbinom(80, 1, 0.6),
                response = rbinom(80, 1, rep(c(0.45, 0.30), each = 40)),
                ae = rbinom(80, 1, rep(c(0.35, 0.20), each = 40)))
eps <- list(Endpoint("OS", "tte", time = "os_tte", event = "os_event"),
            Endpoint("ORR", "binary", var = "response"),
            Endpoint("AE", "binary", var = "ae", higher.better = FALSE))
res <- WinStat(d, eps, treatment = "Cohort1", control = "Cohort2")
res$ci
#>   statistic estimate        se      lower     upper
#> 1       NTB 0.083750 0.1217134 -0.1550319 0.3132865
#> 2        WR 1.216129 0.3486585  0.6933366 2.1331194
#> 3        WO 1.182810 0.2899614  0.7315539 1.9124229
res$by.endpoint
#>   priority endpoint threshold      win     loss undecided
#> 1        1       OS         0 0.292500 0.315000   0.39250
#> 2        2      ORR         0 0.158125 0.026875   0.20750
#> 3        3       AE         0 0.020625 0.045625   0.14125

# response first, then OS with a threshold of 3 months
WinStat(d, eps, treatment = "Cohort1", control = "Cohort2",
        priority = c("ORR", "OS", "AE"), threshold = c(0, 3, 0))$estimate
#>    p_win   p_loss    p_tie      ntb       wr       wo 
#> 0.510000 0.326875 0.163125 0.183125 1.560229 1.448355 

# censored pairs scored with the Kaplan-Meier estimates
WinStat(d, eps, treatment = "Cohort1", control = "Cohort2",
        scoring = "peron")$estimate
#>       p_win      p_loss       p_tie         ntb          wr          wo 
#> 0.548955956 0.447661285 0.003382759 0.101294670 1.226275252 1.225423544 
```
