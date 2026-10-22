test_that("the plotted values are the statistic of each cohort", {
  r <- oc_results()
  class(r) <- c("SimSelection", "data.frame")
  v <- with_null_device(plot(r, "ntb", threshold = 0))
  expect_named(v, c("B", "C"))
  expect_equal(v$B, c(0.1, -0.1, 0))
  expect_equal(v$C, c(0.2, -0.1, -0.2, 0))
  # infinite and missing win ratios are left out
  r$wr[2] <- Inf
  w <- with_null_device(plot(r, "wr"))
  expect_equal(w$B, c(0.9, 1))
  expect_equal(w$C, c(1.2, 1.5))
  expect_error(plot(r, "br"), "br")
  expect_error(plot(r, "ntb", threshold = "a"), "threshold")
})
