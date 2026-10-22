# Selection probabilities of a decision rule

Computes, from the results of
[`SimSelection`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection.md),
the proportion of simulated trials in which a decision rule selects each
cohort.

## Usage

``` r
SelectionOC(
  results,
  statistic = c("br_diff", "br_ref", "ntb", "ntb_lower", "wr", "wo"),
  threshold = NULL,
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

- threshold:

  Numeric vector of thresholds.

- admissibility:

  Logical: use the admissibility of the benefit-risk scores (`"br_diff"`
  and `"br_ref"` only).

## Value

A data frame of class `SelectionOC` with columns `statistic`,
`threshold`, `group` and `p_select`, with one row per threshold and
cohort (in the order of `results`), and, for `"br_diff"` with
admissibility, a row `"(none)"` for the trials in which no cohort is
selected. See
[`SelectionOC-methods`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SelectionOC-methods.md)
for [`print()`](https://rdrr.io/r/base/print.html) and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Details

In each simulated trial, the cohorts other than the reference cohort
whose `statistic` exceeds `threshold` are candidates, and the candidate
with the largest statistic is selected; without a candidate, the
reference cohort is selected. A cohort with a missing statistic (for
example a win ratio when no pair is decided) is not a candidate. The
statistics are

- `"br_diff"`: the difference of the benefit-risk scores against target
  values from that of the reference cohort. With `admissibility = TRUE`,
  a candidate must be admissible; when the reference cohort is not
  admissible, every admissible cohort is a candidate whatever the
  threshold, and no cohort is selected when none is admissible.

- `"br_ref"`: the benefit-risk score relative to the reference cohort.
  With `admissibility = TRUE`, a candidate must also be admissible
  relative to the reference cohort.

- `"ntb"`, `"ntb_lower"`, `"wr"`, `"wo"`: the net treatment benefit
  against the reference cohort, its lower confidence bound, the win
  ratio and the win odds.

The default thresholds are 0 for the differences and the net treatment
benefit and 1 for the win ratio and the win odds; `"br_ref"` has no
default.

## See also

[`SimSelection`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection.md),
[`CalibrateThreshold`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/CalibrateThreshold.md)

## Examples

``` r
res <- data.frame(sim = rep(1:4, each = 3),
                  group = rep(c("A", "B", "C"), 4),
                  is_reference = rep(c(TRUE, FALSE, FALSE), 4),
                  br_diff = c(NA, 0.2, 0.1, NA, -0.1, 0.05, NA, 0.3, 0.4, NA, 0, -0.2),
                  adm = c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE, FALSE,
                          FALSE, FALSE, FALSE),
                  ntb = c(NA, 0.1, -0.1, NA, -0.2, 0.05, NA, 0.3, 0.1, NA, 0.02, 0.01))
SelectionOC(res, "br_diff", threshold = c(0, 0.1))
#> Probability that the rule selects each cohort
#> Statistic: br_diff (Difference of the benefit-risk scores from the reference)
#> 
#>  threshold    A   B C (none)
#>        0.0 0.25 0.5 0   0.25
#>        0.1 0.25 0.5 0   0.25
SelectionOC(res, "ntb")
#> Probability that the rule selects each cohort
#> Statistic: ntb (Net treatment benefit against the reference)
#> 
#>  threshold A    B    C
#>          0 0 0.75 0.25
```
