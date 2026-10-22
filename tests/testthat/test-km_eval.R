test_that("survival, left limits and values beyond the largest time are returned", {
  k <- .km(c(4, 6, 8, 10, 8, 3), c(1, 0, 1, 0, 0, 1))
  expect_equal(.km_eval(k, c(0, 3, 3.5, 4, 8, 9, 10, 11)),
               c(1, 5 / 6, 5 / 6, 2 / 3, 4 / 9, 4 / 9, 4 / 9, NA), tolerance = 1e-15)
  expect_equal(.km_eval(k, c(3, 4, 8, 10, 11), left = TRUE, beyond = "last"),
               c(1, 5 / 6, 2 / 3, 4 / 9, 4 / 9), tolerance = 1e-15)
  expect_equal(.km_eval(k, c(10, 11), beyond = "zero"), c(4 / 9, 0), tolerance = 1e-15)
  m <- matrix(c(0, 4, 8, 12), 2, 2)
  v <- .km_eval(k, m, beyond = "zero")
  expect_equal(dim(v), c(2L, 2L))
  expect_equal(v, matrix(c(1, 2 / 3, 4 / 9, 0), 2, 2), tolerance = 1e-15)
})
