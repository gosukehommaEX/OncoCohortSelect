# Changelog

## OncoCohortSelect 0.1.0

- First version.
- [`Endpoint()`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/Endpoint.md)
  defines binary and time-to-event endpoints; any number of endpoints
  can be used.
- [`PosteriorProb()`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/PosteriorProb.md)
  and
  [`BenefitRisk()`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/BenefitRisk.md)
  compute the posterior benefit-risk score of Chakraborty et al. (2026)
  with beta-binomial models for rates and exponential models with gamma
  priors for survival probabilities and hazard ratios, against target
  values or relative to a reference cohort, with admissibility cutoffs
  and weights.
- [`WinStat()`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/WinStat.md)
  computes the net treatment benefit, the win ratio and the win odds of
  prioritized endpoints with the scoring rule of Gehan, standard errors
  from the first-order H-decomposition and confidence intervals.
- [`SimCohorts()`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimCohorts.md)
  simulates cohorts with correlated progression-free survival, overall
  survival and response (CorOncoEndpoints) and an independent adverse
  event;
  [`SimSelection()`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection.md),
  [`SelectionOC()`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SelectionOC.md)
  and
  [`CalibrateThreshold()`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/CalibrateThreshold.md)
  evaluate selection rules by simulation.
- Tests against independent Python values, the example of Section S.4 of
  Chakraborty et al. (2026) and the BuyseTest package; validation
  scripts in `inst/validation` and `inst/reproduce`.
