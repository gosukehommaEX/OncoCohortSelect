# OncoCohortSelect: selection between single-arm oncology cohorts

Selects one of several single-arm cohorts with multiple efficacy and
safety endpoints for further development, by a posterior benefit-risk
score and by generalized pairwise comparisons, and evaluates the
selection rules by simulation.

- [`Endpoint`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/Endpoint.md)
  defines binary and time-to-event endpoints.

- [`PosteriorProb`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/PosteriorProb.md)
  computes the posterior probability of a favorable value of one
  endpoint, for one cohort or relative to a reference cohort.

- [`BenefitRisk`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/BenefitRisk.md)
  combines the posterior probabilities into a benefit-risk score with
  admissibility criteria.

- [`WinStat`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/WinStat.md)
  computes the net treatment benefit, the win ratio and the win odds of
  prioritized endpoints.

- [`SimCohorts`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimCohorts.md),
  [`SimSelection`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection.md),
  [`SelectionOC`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SelectionOC.md)
  and
  [`CalibrateThreshold`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/CalibrateThreshold.md)
  simulate cohorts and evaluate the selection rules.

## See also

Useful links:

- <https://github.com/gosukehommaEX/OncoCohortSelect>

- <https://gosukehommaEX.github.io/OncoCohortSelect/>

- Report bugs at
  <https://github.com/gosukehommaEX/OncoCohortSelect/issues>

## Author

**Maintainer**: Gosuke Homma <my.name.is.gosuke@gmail.com>

Authors:

- Gosuke Homma <my.name.is.gosuke@gmail.com>
