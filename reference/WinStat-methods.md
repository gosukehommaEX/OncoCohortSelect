# Print and plot win statistics

[`print()`](https://rdrr.io/r/base/print.html) shows the cohorts
compared, the proportions of pairs won, lost and undecided at each
priority level, and the net treatment benefit, the win ratio and the win
odds with their confidence intervals.
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) draws one bar
per priority level with the proportions of all pairs won and lost at
that level, and a last bar with the pairs that no level decides; the
title gives the net treatment benefit and the win ratio with their
confidence intervals.

## Usage

``` r
# S3 method for class 'WinStat'
plot(x, main = NULL, ...)

# S3 method for class 'WinStat'
print(x, digits = 3, ...)
```

## Arguments

- x:

  List returned by
  [`WinStat`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/WinStat.md).

- main:

  Title of the plot; by default the net treatment benefit and the win
  ratio with their confidence intervals.

- ...:

  Not used.

- digits:

  Number of significant digits.

## Value

[`print()`](https://rdrr.io/r/base/print.html) returns `x` invisibly.
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) returns
invisibly the matrix of plotted proportions (rows `won`, `lost` and
`undecided`; one column per bar, from the bottom to the top of the
plot).

## See also

[`WinStat`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/WinStat.md)

## Examples

``` r
set.seed(1)
d <- data.frame(group = rep(c("Cohort1", "Cohort2"), each = 40),
                os_tte = rexp(80, log(2) / rep(c(18, 15), each = 40)),
                os_event = rbinom(80, 1, 0.6),
                response = rbinom(80, 1, rep(c(0.45, 0.30), each = 40)))
eps <- list(Endpoint("OS", "tte", time = "os_tte", event = "os_event"),
            Endpoint("ORR", "binary", var = "response"))
w <- WinStat(d, eps, treatment = "Cohort1", control = "Cohort2")
w
#> Generalized pairwise comparisons: Cohort1 (treatment) vs Cohort2 (control)
#> Patients: 40 and 40 (1600 pairs); scoring rule of Gehan
#> 
#> Proportions of all pairs won, lost and still undecided by priority level:
#>  priority endpoint threshold   win   loss undecided
#>         1       OS         0 0.292 0.3150     0.393
#>         2      ORR         0 0.158 0.0269     0.208
#> 
#> Pairs won 0.451, lost 0.342, tied 0.207
#> 
#> 95% confidence intervals:
#>  statistic estimate    se  lower upper
#>        NTB    0.109 0.118 -0.125 0.331
#>         WR    1.318 0.402  0.725 2.397
#>         WO    1.244 0.298  0.778 1.989
plot(w)
```
