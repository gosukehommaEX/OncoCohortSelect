test_that("sums by key include keys without elements", {
  expect_equal(.sum_by(c(1, 2, 3, 4), c(1L, 3L, 1L, 3L), 4L), c(4, 0, 6, 0))
  expect_equal(.sum_by(numeric(0), integer(0), 2L), c(0, 0))
  expect_equal(.sum_by(c(TRUE, FALSE, TRUE), c(2L, 2L, 2L), 2L), c(0, 2))
})
