# Threshold of a decision rule for a given false selection probability

Finds, from the results of
[`SimSelection`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection.md)
under a scenario in which no cohort should be selected over the
reference cohort (for example cohorts that are all identical), the
smallest threshold for which the proportion of simulated trials that
select a cohort other than the reference is at most `alpha`. Decision
rules based on different statistics can then be compared at the same
false selection probability.

## Usage

``` r
CalibrateThreshold(
  results,
  statistic = c("br_diff", "br_ref", "ntb", "ntb_lower", "wr", "wo"),
  alpha = 0.05,
  admissibility = TRUE,
  ref.inadmissible = c("switch", "keep")
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

  Target probability of selecting a cohort other than the reference.

- admissibility:

  Logical: use the admissibility of the benefit-risk scores (`"br_diff"`
  and `"br_ref"` only).

- ref.inadmissible:

  `"switch"` or `"keep"`: the rule of `"br_diff"` with admissibility
  when the reference cohort is not admissible (see
  [`SelectionOC`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SelectionOC.md)).

## Value

A data frame with columns `statistic`, `alpha`, `threshold` and
`p_nonreference` (the achieved proportion of trials that select a cohort
other than the reference).

## Details

The decision rules are those of
[`SelectionOC`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SelectionOC.md):
a cohort other than the reference is selected when the largest statistic
among the candidate cohorts exceeds the threshold. With
`statistic = "br_diff"`, `admissibility = TRUE` and
`ref.inadmissible = "switch"`, trials in which the reference cohort is
not admissible and another cohort is admissible select that cohort
whatever the threshold; when their proportion exceeds `alpha`, no
threshold achieves `alpha` and the result is `NA` with a warning. With
`ref.inadmissible = "keep"`, every selection of another cohort needs the
threshold, so a threshold that achieves `alpha` always exists. The
threshold is one of the simulated values of the statistic (or `-Inf`
when no trial needs to be excluded), and the achieved proportion can be
smaller than `alpha` because of ties and the finite number of trials.

## See also

[`SelectionOC`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SelectionOC.md),
[`SimSelection`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection.md)

## Examples

``` r
set.seed(1)
res <- data.frame(sim = rep(1:500, each = 3), group = rep(c("A", "B", "C"), 500),
                  is_reference = rep(c(TRUE, FALSE, FALSE), 500))
res$ntb <- ifelse(res$is_reference, NA, rnorm(1500, 0, 0.1))
res$wr <- ifelse(res$is_reference, NA, exp(rnorm(1500, 0, 0.3)))
CalibrateThreshold(res, "ntb", alpha = 0.1)
#>   statistic alpha threshold p_nonreference
#> 1       ntb   0.1  0.164408            0.1
CalibrateThreshold(res, "wr", alpha = 0.1)
#>   statistic alpha threshold p_nonreference
#> 1        wr   0.1   1.67811            0.1
```
