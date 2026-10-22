test_that("sizes must be single positive numbers", {
  expect_null(.check_cex(cex.main = 1, cex.lab = 0.5))
  expect_error(.check_cex(cex.main = 0), "cex.main")
  expect_error(.check_cex(cex.lab = "a"), "cex.lab")
  expect_error(.check_cex(cex.axis = c(1, 2)), "cex.axis")
  expect_error(.check_cex(cex.legend = NA_real_), "cex.legend")
})
