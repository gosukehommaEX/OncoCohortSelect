test_that("colors come from the Okabe-Ito palette and are recycled", {
  cols <- .oc_colors(10)
  expect_length(cols, 10)
  expect_identical(cols[1:2], c("#0072B2", "#D55E00"))
  expect_identical(cols[9:10], cols[1:2])
  expect_equal(dim(grDevices::col2rgb(cols)), c(3L, 10L))
})
