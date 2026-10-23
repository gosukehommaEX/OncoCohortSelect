test_that("definitions follow the measure, the direction and the reference", {
  eps <- .check_endpoints(c(fixture_endpoints(),
                            list(Endpoint("tox", "tte", time = "os_time", event = "os_event",
                                          higher.better = FALSE))))
  crit <- .check_criteria(data.frame(endpoint = c("resp", "pfs", "ae"),
                                     target = c(0.3, 0.5, 0.25), time = c(NA, 6, NA)),
                          eps, two.sample = FALSE)
  expect_identical(.br_definitions(crit, FALSE),
                   c("P(rate >= 0.3)", "P(S(6) >= 0.5)", "P(rate <= 0.25)"))
  crit2 <- .check_criteria(data.frame(endpoint = c("resp", "pfs", "os", "ae", "tox", "tox"),
                                      measure = c("rate", "surv", "hr", "rate", "hr", "surv"),
                                      target = c(0.1, 0.05, 0.8, 0.1, 1.2, 0.1),
                                      time = c(NA, 6, NA, NA, NA, 12.5)),
                           eps, two.sample = TRUE)
  expect_identical(.br_definitions(crit2, TRUE),
                   c("P(rate - reference rate >= 0.1)",
                     "P(S(6) - reference S(6) >= 0.05)", "P(HR <= 0.8)",
                     "P(rate - reference rate <= 0.1)", "P(HR >= 1.2)",
                     "P(S(12.5) - reference S(12.5) <= 0.1)"))
})
