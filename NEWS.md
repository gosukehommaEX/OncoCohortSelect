# OncoCohortSelect 0.3.1

* The `plot()` methods have arguments for the colors (`col`), the sizes of
  the title, axis titles, axis labels and legend (`cex.main`, `cex.lab`,
  `cex.axis`, `cex.legend`) and the position of the legend
  (`legend.position`: below the plot by default, above it, inside it or
  none).
* Horizontal legends space their entries by the width of each label.

# OncoCohortSelect 0.3.0

* `print()` and `plot()` methods for the results of `BenefitRisk()`,
  `WinStat()`, `SimSelection()` and `SelectionOC()`, and a `print()` method
  for `Endpoint()`. The results have the classes `BenefitRisk`, `WinStat`,
  `SimSelection` and `SelectionOC`; the data frames remain data frames.
* `WinStat()` returns the cohorts, the scoring rule and the confidence level
  in the element `settings`, and `SimSelection()` returns the reference
  cohort, the scoring rule and the confidence level in the attribute
  `settings`.
* The plots use base graphics (packages graphics and grDevices).
* The example of the article "Posterior benefit-risk score" has larger cohorts
  and clearer differences between them, and the articles show the new plots.

# OncoCohortSelect 0.2.0

## Breaking changes

* `SimSelection()` compares any number of cohorts with a reference cohort:
  the arguments `treatment` and `control` are replaced by `reference` and
  `cohorts`, and the output has one row per simulated trial and cohort
  (columns `sim`, `group`, `is_reference`, `br`, `adm`, `br_diff`, `br_ref`,
  `adm_ref` and the win statistics against the reference cohort).
* `SelectionOC()` returns the probability of selecting each cohort (columns
  `group` and `p_select`, with a row `"(none)"` for `"br_diff"` with
  admissibility), and `CalibrateThreshold()` returns `p_nonreference`, the
  probability of selecting a cohort other than the reference. In each trial,
  the cohorts whose statistic exceeds the threshold are candidates and the
  candidate with the largest statistic is selected.
* An endpoint used more than once in `priority` must have decreasing
  thresholds.

## New features

* `Endpoint()` accepts columns coded as in ADaM data sets: `censor` gives a
  censoring indicator (0 for an event, as `CNSR`) instead of `event`, and
  `positive` lists the values of a binary endpoint that count as 1 (for
  example `c("CR", "PR")` for the best overall response or `"Y"` for a flag).
* `WinStat()` and `SimSelection()` have the argument `scoring`: `"gehan"`
  (default) or `"peron"`, the scoring rule of Peron et al. (2018) that scores
  pairs with censored times by the Kaplan-Meier estimates of the cohorts. An
  endpoint used again with a smaller threshold adds only the pairs decided at
  the new threshold, as in the BuyseTest package. With `"peron"`, the standard
  errors treat the Kaplan-Meier estimates as known.
* Example data of a completed trial with three cohorts in
  `inst/extdata/example_trial.csv`.
* New articles: "Posterior benefit-risk score", "Net benefit and win ratio",
  "Evaluating decision rules by simulation" (three cohorts) and "Analyzing a
  completed trial".

## Verification

* Tests of the Peron scoring rule against hand calculations, an independent
  Python implementation (`inst/validation/python/reference.py`) and, when it
  is installed, the BuyseTest package; `inst/validation/validate_winstat.R`
  also compares the Peron scoring rule with BuyseTest on simulated trials.

# OncoCohortSelect 0.1.0

* First version.
* `Endpoint()` defines binary and time-to-event endpoints; any number of
  endpoints can be used.
* `PosteriorProb()` and `BenefitRisk()` compute the posterior benefit-risk
  score of Chakraborty et al. (2026) with beta-binomial models for rates and
  exponential models with gamma priors for survival probabilities and hazard
  ratios, against target values or relative to a reference cohort, with
  admissibility cutoffs and weights.
* `WinStat()` computes the net treatment benefit, the win ratio and the win
  odds of prioritized endpoints with the scoring rule of Gehan, standard
  errors from the first-order H-decomposition and confidence intervals.
* `SimCohorts()` simulates cohorts with correlated progression-free survival,
  overall survival and response (CorOncoEndpoints) and an independent adverse
  event; `SimSelection()`, `SelectionOC()` and `CalibrateThreshold()` evaluate
  selection rules by simulation.
* Tests against independent Python values, the example of Section S.4 of
  Chakraborty et al. (2026) and the BuyseTest package; validation scripts in
  `inst/validation` and `inst/reproduce`.
