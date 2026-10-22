test_that("defaults and labels are filled in", {
  eps <- .check_endpoints(fixture_endpoints())
  cr <- .check_criteria(data.frame(endpoint = c("resp", "pfs", "os", "ae"),
                                   target = c(0.3, 0.5, 0.6, 0.3), time = c(NA, 6, 12.5, NA)),
                        eps, two.sample = FALSE)
  expect_identical(cr$measure, c("rate", "surv", "surv", "rate"))
  expect_identical(cr$label, c("resp", "pfs_S6", "os_S12.5", "ae"))
  expect_equal(cr$weight, rep(1 / 4, 4))
  expect_true(all(is.na(cr$cutoff)))
  expect_equal(cr$prior.a, rep(0.5, 4))
  expect_equal(cr$prior.b, c(0.5, 0, 0, 0.5))
  expect_identical(cr$higher.better, c(TRUE, TRUE, TRUE, FALSE))
  cr2 <- .check_criteria(data.frame(endpoint = c("os", "os"), measure = c("hr", "surv"),
                                    target = c(0.8, 0.1), time = c(NA, 12)),
                         eps, two.sample = TRUE)
  expect_identical(cr2$label, c("os_HR", "os_S12"))
  expect_true(is.na(cr2$time[1]))
  cr3 <- .check_criteria(data.frame(endpoint = c("ae", "ae"), target = c(0.2, 0.3)),
                         eps, two.sample = FALSE)
  expect_identical(cr3$label, c("ae", "ae.1"))
})

test_that("invalid criteria give errors", {
  eps <- .check_endpoints(fixture_endpoints())
  ck <- function(df, two = FALSE) .check_criteria(df, eps, two.sample = two)
  expect_error(ck(data.frame(endpoint = "resp")), "target")
  expect_error(ck(data.frame(endpoint = "x", target = 0.3)), "endpoint")
  expect_error(ck(data.frame(endpoint = "resp", target = 0.3, measure = "surv")), "measure")
  expect_error(ck(data.frame(endpoint = "os", target = 0.8, measure = "hr")), "reference")
  expect_error(ck(data.frame(endpoint = "os", target = 0.5)), "time")
  expect_error(ck(data.frame(endpoint = "resp", target = 1.5)), "outside")
  expect_error(ck(data.frame(endpoint = "os", target = 1, time = 6)), "outside")
  expect_error(ck(data.frame(endpoint = "resp", target = 1), two = TRUE), "outside")
  expect_error(ck(data.frame(endpoint = "os", target = 0, measure = "hr"), two = TRUE),
               "outside")
  expect_error(ck(data.frame(endpoint = "resp", target = 0.3, weight = -1)), "weight")
  expect_error(ck(data.frame(endpoint = "resp", target = 0.3, cutoff = 2)), "cutoff")
  expect_error(ck(data.frame(endpoint = "resp", target = 0.3, prior.b = 0)), "prior")
  expect_error(ck(data.frame(endpoint = "os", target = 0.5, time = 6, prior.a = 0)), "prior")
  expect_error(ck(data.frame(endpoint = character(0), target = numeric(0))), "one row")
})
