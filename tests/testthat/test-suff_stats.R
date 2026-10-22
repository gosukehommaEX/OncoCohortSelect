test_that("sufficient statistics are computed by group", {
  d <- data.frame(r = c(1, 0, NA, 1, 1), t = c(2, 3, 4, 5, 6), e = c(1, 0, 1, 1, 0))
  key <- c(1L, 1L, 1L, 2L, 2L)
  sb <- .suff_stats(d, Endpoint("R", var = "r"), key, 3L)
  expect_equal(sb$s1, c(1, 2, 0))
  expect_equal(sb$s2, c(2, 2, 0))
  st <- .suff_stats(d, Endpoint("T", "tte", time = "t", event = "e"), key, 3L)
  expect_equal(st$s1, c(2, 1, 0))
  expect_equal(st$s2, c(9, 11, 0))
})

test_that("positive values and censoring indicators give the same statistics", {
  d <- data.frame(bor = c("PR", "PD", NA, "CR", "CR"), t = c(2, 3, 4, 5, 6),
                  cn = c(0, 1, 0, 0, 1), stringsAsFactors = FALSE)
  key <- c(1L, 1L, 1L, 2L, 2L)
  sb <- .suff_stats(d, Endpoint("R", var = "bor", positive = c("CR", "PR")), key, 3L)
  expect_equal(sb$s1, c(1, 2, 0))
  expect_equal(sb$s2, c(2, 2, 0))
  st <- .suff_stats(d, Endpoint("T", "tte", time = "t", censor = "cn"), key, 3L)
  expect_equal(st$s1, c(2, 1, 0))
  expect_equal(st$s2, c(9, 11, 0))
})
