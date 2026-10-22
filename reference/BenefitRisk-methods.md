# Print and plot benefit-risk scores

[`print()`](https://rdrr.io/r/base/print.html) shows the definition,
weight and cutoff of each component and the scores of the cohorts.
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) draws, for each
cohort, the posterior probabilities of the components and the composite
score as bars, with the admissibility cutoffs as dashed lines.

## Usage

``` r
# S3 method for class 'BenefitRisk'
plot(
  x,
  col = NULL,
  main = NULL,
  legend.position = c("bottom", "top", "topright", "topleft", "bottomright",
    "bottomleft", "right", "left", "none"),
  cex.main = 1.2,
  cex.lab = 1,
  cex.axis = 1,
  cex.legend = 0.9,
  ...
)

# S3 method for class 'BenefitRisk'
print(x, digits = 3, ...)
```

## Arguments

- x:

  Data frame returned by
  [`BenefitRisk`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/BenefitRisk.md).

- col:

  Colors of the bars: one per component and one for the score
  (recycled).

- main:

  Title of the plot.

- legend.position:

  Position of the legend: `"bottom"` (below the plot, the default) or
  `"top"` (above the plot) for a horizontal legend, a keyword of
  [`legend`](https://rdrr.io/r/graphics/legend.html) such as
  `"topright"` for a legend inside the plot, or `"none"`.

- cex.main, cex.lab, cex.axis, cex.legend:

  Sizes of the title, of the axis titles, of the axis and bar labels,
  and of the legend (and notes), relative to the default size.

- ...:

  Not used.

- digits:

  Number of significant digits of the scores.

## Value

[`print()`](https://rdrr.io/r/base/print.html) returns `x` invisibly.
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) returns
invisibly the matrix of plotted values, with one row per component and a
last row `BR`, and one column per cohort.

## See also

[`BenefitRisk`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/BenefitRisk.md)

## Examples

``` r
set.seed(1)
d <- data.frame(group = rep(c("Cohort1", "Cohort2"), each = 40),
                pfs_tte = rexp(80, log(2) / rep(c(8, 6), each = 40)),
                pfs_event = 1,
                response = rbinom(80, 1, rep(c(0.45, 0.30), each = 40)),
                ae = rbinom(80, 1, rep(c(0.35, 0.20), each = 40)))
eps <- list(Endpoint("PFS", "tte", time = "pfs_tte", event = "pfs_event"),
            Endpoint("ORR", "binary", var = "response"),
            Endpoint("AE", "binary", var = "ae", higher.better = FALSE))
crit <- data.frame(endpoint = c("ORR", "PFS", "AE"), target = c(0.3, 0.5, 0.3),
                   time = c(NA, 6, NA), cutoff = c(NA, NA, 0.5))
br <- BenefitRisk(d, eps, crit)
br
#> Posterior benefit-risk scores against target values
#> 
#>  component definition     weight cutoff
#>  ORR       P(rate >= 0.3) 0.333        
#>  PFS_S6    P(S(6) >= 0.5) 0.333        
#>  AE        P(rate <= 0.3) 0.333  0.5   
#> 
#>    group   ORR PFS_S6    AE admissible    BR selected
#>  Cohort1 0.996  0.955 0.627       TRUE 0.842     TRUE
#>  Cohort2 0.509  0.869 0.995       TRUE 0.761    FALSE
#> 
#> Selected: Cohort1
plot(br)

plot(br, col = c("grey80", "grey60", "grey40", "black"), legend.position = "top",
     cex.axis = 1.2)
```
