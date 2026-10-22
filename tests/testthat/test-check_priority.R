test_that("the priority order and the thresholds are completed", {
  eps <- .check_endpoints(fixture_endpoints())
  p <- .check_priority(eps)
  expect_named(p$endpoints, c("os", "pfs", "resp", "ae"))
  expect_equal(p$threshold, c(0, 0, 0, 0))
  p2 <- .check_priority(eps, c("os", "resp", "os"), c(3, NA, 0))
  expect_named(p2$endpoints, c("os", "resp", "os"))
  expect_equal(p2$threshold, c(3, 0, 0))
})

test_that("invalid priorities and thresholds give errors", {
  eps <- .check_endpoints(fixture_endpoints())
  expect_error(.check_priority(eps, "orr"), "priority")
  expect_error(.check_priority(eps, character(0)), "priority")
  expect_error(.check_priority(eps, c("os", "pfs"), 1), "one value")
  expect_error(.check_priority(eps, c("os", "resp"), c(1, 1)), "binary")
  expect_error(.check_priority(eps, c("os", "resp"), c(-1, 0)), "non-negative")
  expect_error(.check_priority(eps, c("os", "resp"), c(NA, 0)), "non-negative")
  expect_error(.check_priority(eps, c("os", "resp"), c("a", "b")), "numeric")
  # an endpoint used again needs a smaller threshold
  expect_error(.check_priority(eps, c("os", "resp", "os"), c(0, 0, 3)), "decreasing")
  expect_error(.check_priority(eps, c("os", "os"), c(1, 1)), "decreasing")
  expect_error(.check_priority(eps, c("resp", "resp"), c(0, 0)), "decreasing")
  expect_named(.check_priority(eps, c("os", "pfs", "os", "os"), c(3, 0, 1, 0))$endpoints,
               c("os", "pfs", "os", "os"))
})
