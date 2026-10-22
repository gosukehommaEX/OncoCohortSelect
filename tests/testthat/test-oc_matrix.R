test_that("selection probabilities are arranged by threshold and cohort", {
  x <- data.frame(statistic = "ntb", threshold = rep(c(0.2, 0.1), each = 2),
                  group = rep(c("B", "A"), 2), p_select = c(0.1, 0.9, 0.3, 0.7))
  M <- .oc_matrix(x)
  expect_identical(dimnames(M), list(c("0.2", "0.1"), c("B", "A")))
  expect_equal(unname(M), rbind(c(0.1, 0.9), c(0.3, 0.7)))
})
