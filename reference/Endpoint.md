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
  censor = NULL,
  positive = NULL,
  higher.better = TRUE
)

# S3 method for class 'Endpoint'
print(x, ...)
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

- time:

  For a time-to-event endpoint, the name of the column with the observed
  times.

- event:

  For a time-to-event endpoint, the name of the column with the event
  indicators (1 = event, 0 = censored). Give `event` or `censor`.

- censor:

  For a time-to-event endpoint, the name of the column with the
  censoring indicators (0 = event, other values = censored).

- positive:

  For a binary endpoint, optional vector of the values of `var` that
  count as 1; other non-missing values count as 0.

- higher.better:

  Logical: `TRUE` if a value of 1 (binary) or a longer time (time to
  event) is favorable.

- x:

  An `Endpoint` object.

- ...:

  Not used.

## Value

An object of class `Endpoint`: a list with elements `name`, `type`,
`var`, `time`, `event`, `censor`, `positive` and `higher.better`.

## Details

A binary endpoint is a column with values 0, 1 or `NA`, for example the
objective response (`higher.better = TRUE`) or the occurrence of an
adverse event (`higher.better = FALSE`). With `positive`, the column can
hold any codes: the values in `positive` count as 1 and the other values
as 0, for example `positive = c("CR", "PR")` for a best overall response
or `positive = "Y"` for a flag that is `"Y"` or blank. Missing values
(`NA`) are excluded from the posterior distribution in
[`BenefitRisk`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/BenefitRisk.md)
and make a pair uninformative for this endpoint in
[`WinStat`](https://gosukehommaEX.github.io/OncoCohortSelect/reference/WinStat.md).

A time-to-event endpoint is given by a column of observed times and
either a column of event indicators (`event`: 1 for an event, 0 for
censoring) or a column of censoring indicators (`censor`: 0 for an
event, any other value for censoring, as the variable `CNSR` of ADaM
data sets), for example overall survival or progression-free survival.
With `higher.better = TRUE` (the usual case) longer times are favorable.

The columns are named freely, so that data with any variable names (for
example ADaM data sets restructured to one row per patient) can be
analyzed, and any number of endpoints can be defined.

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

# variables in the style of ADaM data sets
adam_eps <- list(
  Endpoint("OS", "tte", time = "OSAVAL", censor = "OSCNSR"),
  Endpoint("ORR", "binary", var = "BOR", positive = c("CR", "PR")),
  Endpoint("AE", "binary", var = "AEFL", positive = "Y", higher.better = FALSE)
)
```
