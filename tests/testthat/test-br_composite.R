test_that("the composite score and admissibility follow their definitions", {
  S <- matrix(c(0.9, 0.5, 0.8, 0.2, 0.7, 0), 2, 3)
  crit <- data.frame(weight = c(0.5, 0.25, 0.25), cutoff = c(0.6, NA, 0.5))
  res <- .br_composite(S, crit)
  expect_equal(res$BR, c(0.9 ^ 0.5 * 0.8 ^ 0.25 * 0.7 ^ 0.25, 0), tolerance = 1e-14)
  expect_identical(res$admissible, c(TRUE, FALSE))
  # a zero weight removes the component
  crit$weight <- c(0.5, 0.5, 0)
  expect_equal(.br_composite(S, crit)$BR, sqrt(c(0.9 * 0.8, 0.5 * 0.2)), tolerance = 1e-14)
  # without cutoffs every row is admissible
  crit$cutoff <- NA
  expect_identical(.br_composite(S, crit)$admissible, c(TRUE, TRUE))
})
