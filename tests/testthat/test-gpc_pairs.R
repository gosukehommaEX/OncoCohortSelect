test_that("pairs are decided by the first endpoint that decides them", {
  xt <- data.frame(t = c(5, 10), e = c(1, 0), r = c(1, 0))
  xc <- data.frame(t = c(5, 3), e = c(1, 1), r = c(0, 1))
  eps <- list(Endpoint("T", "tte", time = "t", event = "e"), Endpoint("R", var = "r"))
  p <- .gpc_pairs(xt, xc, eps, c(0, 0))
  # pair (1, 1): tie on T, win on R; (1, 2): win on T; (2, 1): win on T; (2, 2): win on T
  expect_identical(p$win, matrix(1, 2, 2))
  expect_identical(p$loss, matrix(0, 2, 2))
  expect_equal(p$win.k, c(3, 1))
  expect_equal(p$loss.k, c(0, 0))
  # with R first: (1, 1) win, (1, 2) tie then T win, (2, 1) tie then T win, (2, 2) loss
  p2 <- .gpc_pairs(xt, xc, eps[c(2, 1)], c(0, 0))
  expect_identical(p2$win, matrix(c(1, 1, 1, 0), 2, 2))
  expect_identical(p2$loss, matrix(c(0, 0, 0, 1), 2, 2))
  expect_equal(p2$win.k, c(1, 2))
  expect_equal(p2$loss.k, c(1, 0))
})

test_that("an endpoint used again adds only the pairs decided at the new threshold", {
  ex <- peron_example()
  xt <- transform(ex$xt, r = c(1, 0, 1))
  xc <- transform(ex$xc, r = c(0, 1, 1, 0))
  eps <- list(T = ex$ep, R = Endpoint("R", var = "r"))
  for (sc in c("gehan", "peron")) {
    f <- if (sc == "peron") .gpc_score_peron else .gpc_score
    s2 <- f(xt, xc, ex$ep, 2)
    s0 <- f(xt, xc, ex$ep, 0)
    r <- .gpc_score(xt, xc, eps$R)
    # T with threshold 2, then R, then T with threshold 0
    p <- .gpc_pairs(xt, xc, eps[c("T", "R", "T")], c(2, 0, 0), sc)
    rest_t <- 1 - s2$win - s2$loss
    rest_r <- 1 - r$win - r$loss
    expect_equal(p$win, s2$win + rest_t * r$win + rest_r * (s0$win - s2$win),
                 tolerance = 1e-14)
    expect_equal(p$loss, s2$loss + rest_t * r$loss + rest_r * (s0$loss - s2$loss),
                 tolerance = 1e-14)
    expect_equal(p$win.k, c(sum(s2$win), sum(rest_t * r$win),
                            sum(rest_r * (s0$win - s2$win))), tolerance = 1e-14)
    # T with threshold 2 then 0 is T with threshold 0
    p0 <- .gpc_pairs(xt, xc, eps[c("T", "T")], c(2, 0), sc)
    expect_equal(p0$win, s0$win * 1, tolerance = 1e-14)
    expect_equal(p0$loss, s0$loss * 1, tolerance = 1e-14)
  }
  # the example has pairs partly decided at threshold 2 and decided at 0
  s2 <- .gpc_score_peron(xt, xc, ex$ep, 2)
  expect_true(any(s2$win + s2$loss > 0 & s2$win + s2$loss < 1))
})
