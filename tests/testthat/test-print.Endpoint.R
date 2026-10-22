test_that("endpoints are printed with their columns and favorable direction", {
  e1 <- Endpoint("OS", "tte", time = "AVAL", censor = "CNSR")
  out <- capture.output(v <- withVisible(print(e1)))
  expect_false(v$visible)
  expect_identical(v$value, e1)
  expect_identical(out, c("<Endpoint> OS: time to event",
                          "  time: AVAL, censor: CNSR (0 = event)",
                          "  favorable: longer times"))
  e2 <- Endpoint("TOX", "tte", time = "t", event = "e", higher.better = FALSE)
  expect_identical(capture.output(print(e2)),
                   c("<Endpoint> TOX: time to event", "  time: t, event: e (1 = event)",
                     "  favorable: shorter times"))
  e3 <- Endpoint("ORR", var = "BOR", positive = c("CR", "PR"))
  expect_identical(capture.output(print(e3)),
                   c("<Endpoint> ORR: binary", "  values: BOR (CR, PR count as 1)",
                     "  favorable: a value of 1"))
  e4 <- Endpoint("AE", var = "ae", higher.better = FALSE)
  expect_identical(capture.output(print(e4)),
                   c("<Endpoint> AE: binary", "  values: ae", "  favorable: a value of 0"))
})
