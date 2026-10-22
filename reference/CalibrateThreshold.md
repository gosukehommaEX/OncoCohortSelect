# Threshold of a decision rule for a given false selection probability

Finds, from the results of
[`SimSelection`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection.md)
under a scenario in which the treatment cohort should not be selected
(for example identical cohorts), the smallest threshold for which the
proportion of simulated trials that select the treatment cohort is at
most `alpha`. Decision rules based on different statistics can then be
compared at the same false selection probability.

## Usage

``` r
CalibrateThreshold(
  results,
  statistic = c("br_diff", "br_ref", "ntb", "ntb_lower", "wr", "wo"),
  alpha = 0.05,
  admissibility = TRUE
)
```

## Arguments

- results:

  Data frame returned by
  [`SimSelection`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection.md).

- statistic:

  One of `"br_diff"`, `"br_ref"`, `"ntb"`, `"ntb_lower"`, `"wr"` and
  `"wo"`.

- alpha:

  Target probability of selecting the treatment cohort.

- admissibility:

  Logical: use the admissibility of the benefit-risk scores (`"br_diff"`
  and `"br_ref"` only).

## Value

A data frame with columns `statistic`, `alpha`, `threshold` and
`p_treatment` (the achieved proportion).

## Details

The decision rules are those of
[`SelectionOC`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SelectionOC.md).
With `statistic = "br_diff"` and `admissibility = TRUE`, trials in which
only the treatment cohort is admissible select it whatever the
threshold; when their proportion exceeds `alpha`, no threshold achieves
`alpha` and the result is `NA` with a warning. The threshold is one of
the simulated values of the statistic (or `-Inf` when no trial needs to
be excluded), and the achieved proportion can be smaller than `alpha`
because of ties and the finite number of trials.

## See also

[`SelectionOC`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SelectionOC.md),
[`SimSelection`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection.md)

## Examples

``` r
set.seed(1)
res <- data.frame(ntb = rnorm(1000, 0, 0.1), wr = exp(rnorm(1000, 0, 0.3)))
CalibrateThreshold(res, "ntb", alpha = 0.1)
#>   statistic alpha threshold p_treatment
#> 1       ntb   0.1 0.1324004         0.1
CalibrateThreshold(res, "wr", alpha = 0.1)
#>   statistic alpha threshold p_treatment
#> 1        wr   0.1  1.478975         0.1
```
