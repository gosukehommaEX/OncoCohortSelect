# Selection probabilities of a decision rule

Computes, from the results of
[`SimSelection`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection.md),
the proportions of simulated trials in which a decision rule selects the
treatment cohort, the control cohort or neither.

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

  Numeric vector of thresholds; one row of the output per value.

- admissibility:

  Logical: use the admissibility of the benefit-risk scores (`"br_diff"`
  and `"br_ref"` only).

## Value

A data frame with columns `statistic`, `threshold`, `p_treatment`,
`p_control` and `p_none`.

## Details

The treatment cohort is selected when `statistic` exceeds `threshold`;
otherwise the control cohort is selected. The statistics are

- `"br_diff"`: the difference of the benefit-risk scores against target
  values. With `admissibility = TRUE`, the scores are compared only when
  both cohorts are admissible; an admissible cohort is selected over one
  that is not, and neither is selected when neither is admissible.

- `"br_ref"`: the benefit-risk score of the treatment cohort relative to
  the control cohort. With `admissibility = TRUE`, the treatment cohort
  must also be admissible relative to the control cohort.

- `"ntb"`, `"ntb_lower"`, `"wr"`, `"wo"`: the net treatment benefit, its
  lower confidence bound, the win ratio and the win odds.

A missing statistic (for example a win ratio when no pair is decided)
selects the control cohort. The default thresholds are 0 for the
differences and the net treatment benefit and 1 for the win ratio and
the win odds; `"br_ref"` has no default.

## See also

[`SimSelection`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection.md),
[`CalibrateThreshold`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/CalibrateThreshold.md)

## Examples

``` r
res <- data.frame(br_diff = c(0.2, -0.1, 0.05, 0.3), adm_trt = c(TRUE, TRUE, FALSE, TRUE),
                  adm_ctl = c(TRUE, TRUE, TRUE, FALSE), ntb = c(0.1, -0.2, 0.05, 0.3),
                  wr = c(1.3, 0.6, 1.1, 2))
SelectionOC(res, "br_diff", threshold = c(0, 0.1))
#>   statistic threshold p_treatment p_control p_none
#> 1   br_diff       0.0         0.5       0.5      0
#> 2   br_diff       0.1         0.5       0.5      0
SelectionOC(res, "wr")
#>   statistic threshold p_treatment p_control p_none
#> 1        wr         1        0.75      0.25      0
```
