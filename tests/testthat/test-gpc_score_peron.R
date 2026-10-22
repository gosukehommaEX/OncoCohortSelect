test_that("the probabilities agree with a hand calculation", {
  ex <- peron_example()
  # for example, treatment 5 against control 6: the treatment time is 7 or
  # beyond 9 (1/2 each) and the control time is 8 or beyond 10 (1/2 each), so
  # the treatment time is longer with probability 1/4 (beyond 9 against 8) and
  # shorter with probability 1/2 (7 against 8, and 7 against beyond 10)
  win0 <- rbind(c(1, 0.25, 0.5, 0), c(1, 0, 0, 0), c(1, 0.5, 1, 0))
  loss0 <- rbind(c(0, 0.5, 0.5, 0.5), c(0, 1, 1, 1), c(0, 0, 0, 0))
  s <- .gpc_score_peron(ex$xt, ex$xc, ex$ep, 0)
  expect_equal(s$win, win0, tolerance = 1e-14)
  expect_equal(s$loss, loss0, tolerance = 1e-14)
  # with a threshold of 1 nothing changes: a difference of exactly 1 counts
  s1 <- .gpc_score_peron(ex$xt, ex$xc, ex$ep, 1)
  expect_equal(s1$win, win0, tolerance = 1e-14)
  expect_equal(s1$loss, loss0, tolerance = 1e-14)
  # with a threshold of 2, only differences of at least 2 count
  s2 <- .gpc_score_peron(ex$xt, ex$xc, ex$ep, 2)
  expect_equal(s2$win, cbind(c(1, 1, 1), matrix(0, 3, 3)), tolerance = 1e-14)
  expect_equal(s2$loss, rbind(c(0, 0.25, 0, 0.5), c(0, 0.5, 0, 1), c(0, 0, 0, 0)),
               tolerance = 1e-14)
})

test_that("a lower value that is better swaps the probabilities", {
  ex <- peron_example()
  ep <- Endpoint("T", "tte", time = "t", event = "e", higher.better = FALSE)
  s <- .gpc_score_peron(ex$xt, ex$xc, ep, 0)
  s0 <- .gpc_score_peron(ex$xt, ex$xc, ex$ep, 0)
  expect_identical(s$win, s0$loss)
  expect_identical(s$loss, s0$win)
})

test_that("censoring indicators give the same probabilities as event indicators", {
  ex <- peron_example()
  xt <- transform(ex$xt, cn = 1 - e)
  xc <- transform(ex$xc, cn = 2 * (1 - e))
  ep <- Endpoint("T", "tte", time = "t", censor = "cn")
  expect_identical(.gpc_score_peron(xt, xc, ep, 0), .gpc_score_peron(xt, xc, ex$ep, 0))
})

test_that("binary endpoints are scored as with the Gehan rule", {
  xt <- data.frame(r = c(1, 0, NA))
  xc <- data.frame(r = c(0, 1))
  ep <- Endpoint("R", var = "r")
  s <- .gpc_score_peron(xt, xc, ep)
  g <- .gpc_score(xt, xc, ep)
  expect_identical(s$win, g$win * 1)
  expect_identical(s$loss, g$loss * 1)
  expect_true(is.double(s$win))
})

test_that("the probabilities are bounded and at least the Gehan scores", {
  eps <- fixture_endpoints()
  for (ds in c("ties", "cont", "cens")) {
    d <- fixture(paste0("gpc_", ds, ".csv"))
    xt <- d[d$arm == "T", ]
    xc <- d[d$arm == "C", ]
    for (k in 1:2) {
      for (thr in c(0, 1, 2.5)) {
        s <- .gpc_score_peron(xt, xc, eps[[k]], thr)
        g <- .gpc_score(xt, xc, eps[[k]], thr)
        expect_equal(dim(s$win), c(nrow(xt), nrow(xc)))
        expect_true(all(s$win >= 0 & s$loss >= 0))
        expect_true(all(s$win + s$loss <= 1 + 1e-12))
        # a pair decided by the Gehan rule is decided with probability 1
        expect_true(all(s$win[g$win] == 1))
        expect_true(all(s$loss[g$loss] == 1))
        # and pairs undecided by the Gehan rule can be partly decided (in the
        # data sets with continuous times, always some)
        expect_gte(sum(s$win + s$loss), sum(g$win + g$loss))
        if (ds != "ties") expect_gt(sum(s$win + s$loss), sum(g$win + g$loss))
      }
    }
  }
})
