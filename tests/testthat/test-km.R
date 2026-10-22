test_that("the Kaplan-Meier estimate agrees with a hand calculation", {
  # ordered: 3 (event), 4 (event), 6, 8 (event), 8, 10; at risk 6, 5 and 3
  k <- .km(c(4, 6, 8, 10, 8, 3), c(1, 0, 1, 0, 0, 1))
  expect_equal(k$time, c(3, 4, 8))
  expect_equal(k$surv, c(5 / 6, 2 / 3, 4 / 9), tolerance = 1e-15)
  expect_equal(k$tmax, 10)
  expect_equal(k$last, 4 / 9, tolerance = 1e-15)
  # tied events
  k2 <- .km(c(2, 2, 5), c(1, 1, 0))
  expect_equal(k2$surv, 1 / 3, tolerance = 1e-15)
  # no event
  k3 <- .km(c(2, 5), c(0, 0))
  expect_length(k3$time, 0)
  expect_equal(k3$last, 1)
  # all patients have an event
  k4 <- .km(c(1, 2), c(1, 1))
  expect_equal(k4$surv, c(1 / 2, 0))
  expect_equal(k4$last, 0)
})
