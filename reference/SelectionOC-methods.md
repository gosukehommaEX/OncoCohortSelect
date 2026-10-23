# Print and plot selection probabilities

[`print()`](https://rdrr.io/r/base/print.html) shows the probability
that the decision rule selects each cohort, with one row per threshold
and one column per cohort.
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) draws these
probabilities against the threshold, one line per cohort, or as bars
when there is a single threshold. Results of several statistics combined
with [`rbind()`](https://rdrr.io/r/base/cbind.html) are printed as a
data frame and cannot be plotted together. The plot names the statistic
in words, for example "Win ratio", with the threshold on a second line
when there is a single threshold, and labels the selection of no cohort
(`"(none)"`, with `"br_diff"` and admissibility) "None admissible". The
plot methods of the package restore the graphical parameters they
change, so elements added afterwards with low-level functions such as
[`abline()`](https://rdrr.io/r/graphics/abline.html) may be misplaced;
use the arguments of the methods, such as `threshold`, instead.

## Usage

``` r
# S3 method for class 'SelectionOC'
plot(
  x,
  threshold = NULL,
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

# S3 method for class 'SelectionOC'
print(x, digits = 3, ...)
```

## Arguments

- x:

  Data frame returned by
  [`SelectionOC`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SelectionOC.md).

- threshold:

  Optional thresholds marked by dashed vertical lines, for example a
  calibrated threshold (several thresholds only).

- col:

  Colors of the cohorts (recycled).

- main:

  Title of the plot.

- legend.position:

  Position of the legend: `"bottom"` (below the plot, the default) or
  `"top"` (above the plot) for a horizontal legend, a keyword of
  [`legend`](https://rdrr.io/r/graphics/legend.html) such as
  `"topright"` for a legend inside the plot, or `"none"`. With a single
  threshold the cohorts are named under the bars and no legend is drawn.

- cex.main, cex.lab, cex.axis, cex.legend:

  Sizes of the title, of the axis titles, of the axis and bar labels,
  and of the legend, relative to the default size.

- ...:

  Not used.

- digits:

  Number of significant digits.

## Value

[`print()`](https://rdrr.io/r/base/print.html) returns `x` invisibly.
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) returns
invisibly the matrix of selection probabilities, with one row per
threshold and one column per cohort.

## See also

[`SelectionOC`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SelectionOC.md)

## Examples

``` r
set.seed(1)
res <- data.frame(sim = rep(1:200, each = 3), group = rep(c("A", "B", "C"), 200),
                  is_reference = rep(c(TRUE, FALSE, FALSE), 200))
res$ntb <- ifelse(res$is_reference, NA,
                  rnorm(600, rep(c(0, 0.05, 0.15), 200), 0.1))
oc <- SelectionOC(res, "ntb", threshold = seq(0, 0.3, by = 0.05))
oc
#> Probability that the rule selects each cohort
#> Statistic: ntb (Net treatment benefit against the reference)
#> 
#>  threshold     A     B     C
#>       0.00 0.010 0.290 0.700
#>       0.05 0.080 0.260 0.660
#>       0.10 0.205 0.205 0.590
#>       0.15 0.460 0.130 0.410
#>       0.20 0.680 0.050 0.270
#>       0.25 0.870 0.010 0.120
#>       0.30 0.935 0.000 0.065
plot(oc)

plot(oc, threshold = 0.15, legend.position = "right", cex.lab = 1.2)
```
