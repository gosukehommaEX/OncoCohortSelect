test_that("endpoint lists are named and their columns are checked", {
  eps <- .check_endpoints(fixture_endpoints(), fixture("gpc_cont.csv"))
  expect_named(eps, c("os", "pfs", "resp", "ae"))
  one <- .check_endpoints(Endpoint("R", var = "r"))
  expect_named(one, "R")
  d <- data.frame(r = c(0, 1, NA), t = c(1, 2, 3), e = c(0, 1, 1))
  expect_error(.check_endpoints(list(Endpoint("R", var = "r"), Endpoint("R", var = "r"))),
               "unique")
  expect_error(.check_endpoints(list(Endpoint("X", var = "x")), d), "not found")
  expect_error(.check_endpoints(list(Endpoint("R", var = "r")), transform(d, r = c(0, 2, 1))),
               "0, 1 or NA")
  expect_error(.check_endpoints(list(Endpoint("T", "tte", time = "t", event = "e")),
                                transform(d, t = c(1, NA, 3))), "times")
  expect_error(.check_endpoints(list(Endpoint("T", "tte", time = "t", event = "e")),
                                transform(d, e = c(0, 2, 1))), "0 and 1")
  expect_error(.check_endpoints(list(1)), "Endpoint")
})

test_that("columns with positive values and censoring indicators are checked", {
  d <- data.frame(bor = c("CR", "SD", NA), t = c(1, 2, 3), cn = c(0, 1, 2),
                  stringsAsFactors = FALSE)
  eps <- list(Endpoint("ORR", var = "bor", positive = c("CR", "PR")),
              Endpoint("T", "tte", time = "t", censor = "cn"))
  expect_named(.check_endpoints(eps, d), c("ORR", "T"))
  # without 'positive', character values are not accepted
  expect_error(.check_endpoints(list(Endpoint("ORR", var = "bor")), d), "positive")
  expect_error(.check_endpoints(eps, transform(d, cn = c(0, NA, 1))), "censoring")
  expect_error(.check_endpoints(eps, transform(d, cn = c("0", "1", "1"))), "censoring")
  expect_error(.check_endpoints(eps, d[, c("bor", "t")]), "not found")
})
