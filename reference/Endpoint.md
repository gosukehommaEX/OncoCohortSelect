# Define an endpoint

Defines a binary or time-to-event endpoint by the columns of a
patient-level data frame that hold it and by the direction in which it
is favorable. The definitions are used by
[`BenefitRisk`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/BenefitRisk.md),
[`WinStat`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/WinStat.md)
and
[`SimSelection`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/SimSelection.md);
any number of endpoints can be defined.

## Usage

``` r
Endpoint(
  name,
  type = c("binary", "tte"),
  var = NULL,
  time = NULL,
  event = NULL,
  higher.better = TRUE
)
```

## Arguments

- name:

  Name of the endpoint, used to refer to it in the criteria of
  [`BenefitRisk`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/BenefitRisk.md)
  and in the priority order of
  [`WinStat`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/WinStat.md).

- type:

  `"binary"` or `"tte"` (time to event).

- var:

  For a binary endpoint, the name of the column with the values.

- time, event:

  For a time-to-event endpoint, the names of the columns with the
  observed times and the event indicators.

- higher.better:

  Logical: `TRUE` if a value of 1 (binary) or a longer time (time to
  event) is favorable.

## Value

An object of class `Endpoint`: a list with elements `name`, `type`,
`var`, `time`, `event` and `higher.better`.

## Details

A binary endpoint is a column with values 0, 1 or `NA`, for example the
objective response (`higher.better = TRUE`) or the occurrence of an
adverse event (`higher.better = FALSE`). Missing values are excluded
from the posterior distribution in
[`BenefitRisk`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/BenefitRisk.md)
and make a pair uninformative for this endpoint in
[`WinStat`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/WinStat.md).

A time-to-event endpoint is given by a column of observed times and a
column of event indicators (1 for an event, 0 for censoring), for
example overall survival or progression-free survival. With
`higher.better = TRUE` (the usual case) longer times are favorable.

## See also

[`BenefitRisk`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/BenefitRisk.md),
[`WinStat`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/WinStat.md)

## Examples

``` r
eps <- list(
  Endpoint("OS", "tte", time = "os_tte", event = "os_event"),
  Endpoint("PFS", "tte", time = "pfs_tte", event = "pfs_event"),
  Endpoint("ORR", "binary", var = "response"),
  Endpoint("AE", "binary", var = "ae", higher.better = FALSE)
)
eps[[4]]$higher.better
#> [1] FALSE
```
