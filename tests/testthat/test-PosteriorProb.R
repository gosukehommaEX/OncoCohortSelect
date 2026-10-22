test_that("posterior probabilities agree with independent Python values", {
  ex <- fixture("posterior_expected.csv")
  got <- vapply(seq_len(nrow(ex)), function(i) {
    r <- ex[i, ]
    PosteriorProb(r$measure, r$a, r$b, target = r$target,
                  time = if (is.na(r$time)) NULL else r$time,
                  a.ref = if (is.na(r$a_ref)) NULL else r$a_ref,
                  b.ref = if (is.na(r$b_ref)) NULL else r$b_ref,
                  higher.better = r$higher_better)
  }, numeric(1))
  expect_length(got, 29)
  expect_false(anyNA(got))
  expect_lt(max(abs(got - ex$expected)), 1e-5)
  # one-sample probabilities and hazard ratios are in closed form
  closed <- is.na(ex$a_ref) | ex$measure == "hr"
  expect_lt(max(abs(got[closed] - ex$expected[closed])), 1e-9)
  # the same comparison fails when one expected value is changed by 1e-4
  changed <- ex$expected
  changed[9] <- changed[9] + 1e-4
  expect_failure(expect_lt(max(abs(got - changed)), 1e-5))
})

test_that("the example of Chakraborty et al. (2026, Section S.4) is reproduced", {
  # inputs of the R code of Section S.4 of the supplementary material
  ss_c <- 50
  ss_d <- 45
  r_c <- c(0.45, 0.36, 0, 0.37, 0.4, 0.45, 0.52)
  r_d <- c(0.73, 0.53, 0, 0.45, 0.5, 0.42, 0.58)
  cut <- c(0.20, 0.10, 0, 0.05, 0.10, 0.15, 0.20)
  pa <- c(0.67, 0.43, rep(0.5, 5))
  pb <- c(1, 1, rep(0.5, 5))
  p <- PosteriorProb("rate", a = pa + ss_d * r_d, b = pb + ss_d - ss_d * r_d, target = cut,
                     a.ref = pa + ss_c * r_c, b.ref = pb + ss_c - ss_c * r_c)
  # P(Delta >= cutoff) computed independently with scipy (adaptive quadrature)
  py <- c(0.771356520447, 0.745176968704, 0.516672527357, 0.614238533832,
          0.494523136060, 0.036599506922, 0.078448948346)
  expect_lt(max(abs(p - py)), 1e-5)
  admissible <- all(p[1:2] > 0.30) && all(p[3:7] < 0.95)
  br <- prod(p[1:2]) ^ (1 / 2) * prod(1 - p[3:7]) ^ (1 / 5)
  # published output of the code: admissible (1) and BR = 0.46
  expect_true(admissible)
  expect_identical(round(br, 2), 0.46)
  expect_lt(abs(br - 0.461609633299), 1e-5)
})

test_that("the two directions are complementary", {
  a <- c(12.5, 3.5)
  b <- c(30.5, 40)
  for (ms in c("rate", "surv")) {
    tm <- if (ms == "surv") 6 else NULL
    tg <- if (ms == "rate") 0.3 else 0.7
    hi <- PosteriorProb(ms, a, b / (if (ms == "surv") 10 else 1), tg, time = tm)
    lo <- PosteriorProb(ms, a, b / (if (ms == "surv") 10 else 1), tg, time = tm,
                        higher.better = FALSE)
    expect_equal(hi + lo, c(1, 1), tolerance = 1e-12)
    hi2 <- PosteriorProb(ms, a, b, 0.05, time = tm, a.ref = rev(a), b.ref = rev(b))
    lo2 <- PosteriorProb(ms, a, b, 0.05, time = tm, a.ref = rev(a), b.ref = rev(b),
                         higher.better = FALSE)
    expect_equal(hi2 + lo2, c(1, 1), tolerance = 1e-12)
  }
  h1 <- PosteriorProb("hr", 10, 200, 0.9, a.ref = 12, b.ref = 210)
  h2 <- PosteriorProb("hr", 10, 200, 0.9, a.ref = 12, b.ref = 210, higher.better = FALSE)
  expect_equal(h1 + h2, 1, tolerance = 1e-12)
})

test_that("identical posterior distributions give 1/2 with a zero margin", {
  expect_equal(PosteriorProb("rate", c(3.5, 20.5), c(10.5, 20.5), 0,
                             a.ref = c(3.5, 20.5), b.ref = c(10.5, 20.5)),
               c(0.5, 0.5), tolerance = 1e-6)
  expect_equal(PosteriorProb("surv", 15.5, 300, 0, time = 6, a.ref = 15.5, b.ref = 300),
               0.5, tolerance = 1e-6)
  expect_equal(PosteriorProb("hr", 15.5, 300, 1, a.ref = 15.5, b.ref = 300), 0.5,
               tolerance = 1e-12)
})

test_that("vector input gives the element-wise results", {
  a <- c(5.5, 20.5, 40.5)
  b <- c(35.5, 20.5, 2.5)
  v <- PosteriorProb("rate", a, b, 0.1, a.ref = 10.5, b.ref = 30.5)
  s <- vapply(1:3, function(i) PosteriorProb("rate", a[i], b[i], 0.1, a.ref = 10.5,
                                             b.ref = 30.5), numeric(1))
  expect_equal(v, s, tolerance = 1e-14)
})

test_that("more nodes change the probability of a difference by less than 1e-6", {
  p200 <- PosteriorProb("surv", 0.5, 5, -0.4, time = 6, a.ref = 0.5, b.ref = 400,
                        higher.better = FALSE)
  p800 <- PosteriorProb("surv", 0.5, 5, -0.4, time = 6, a.ref = 0.5, b.ref = 400,
                        higher.better = FALSE, n.nodes = 800)
  expect_lt(abs(p200 - p800), 1e-6)
})

test_that("invalid arguments give errors", {
  expect_error(PosteriorProb("hr", 1, 1, 0.8), "reference")
  expect_error(PosteriorProb("surv", 1, 1, 0.5), "time")
  expect_error(PosteriorProb("rate", 1, 1, 1.2), "outside")
  expect_error(PosteriorProb("rate", 1, 1, 0.5, a.ref = 1, b.ref = 1), NA)
  expect_error(PosteriorProb("rate", 1, 1, 1, a.ref = 1, b.ref = 1), "outside")
  expect_error(PosteriorProb("rate", 0, 1, 0.5), "positive")
  expect_error(PosteriorProb("rate", 1, 1, 0.5, a.ref = 1), "both")
  expect_error(PosteriorProb("rate", c(1, 2), c(1, 2, 3), 0.5), "common length")
  expect_error(PosteriorProb("rate", 1, 1, 0.5, higher.better = NA), "TRUE or FALSE")
  expect_error(PosteriorProb("rate", 1, 1, 0.5, a.ref = 1, b.ref = 1, n.nodes = 1),
               "n.nodes")
})
