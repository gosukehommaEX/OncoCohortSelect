test_that("pairs are decided by the first endpoint that decides them", {
  xt <- data.frame(t = c(5, 10), e = c(1, 0), r = c(1, 0))
  xc <- data.frame(t = c(5, 3), e = c(1, 1), r = c(0, 1))
  eps <- list(Endpoint("T", "tte", time = "t", event = "e"), Endpoint("R", var = "r"))
  p <- .gpc_pairs(xt, xc, eps, c(0, 0))
  # pair (1, 1): tie on T, win on R; (1, 2): win on T; (2, 1): win on T; (2, 2): win on T
  expect_identical(p$win, matrix(TRUE, 2, 2))
  expect_false(any(p$loss))
  expect_equal(p$win.k, c(3, 1))
  expect_equal(p$loss.k, c(0, 0))
  # with R first: (1, 1) win, (1, 2) tie then T win, (2, 1) tie then T win, (2, 2) loss
  p2 <- .gpc_pairs(xt, xc, eps[c(2, 1)], c(0, 0))
  expect_identical(p2$win, matrix(c(TRUE, TRUE, TRUE, FALSE), 2, 2))
  expect_identical(p2$loss, matrix(c(FALSE, FALSE, FALSE, TRUE), 2, 2))
  expect_equal(p2$win.k, c(1, 2))
  expect_equal(p2$loss.k, c(1, 0))
})
