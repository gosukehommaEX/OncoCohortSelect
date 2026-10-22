test_that("probabilities of differences agree with independent Python values", {
  ex <- fixture("posterior_expected.csv")
  ex <- ex[!is.na(ex$a_ref) & ex$measure != "hr" & ex$higher_better, ]
  got <- vapply(seq_len(nrow(ex)), function(i) {
    r <- ex[i, ]
    .prob_diff(r$measure, r$a, r$b, r$a_ref, r$b_ref, r$target,
               time = if (is.na(r$time)) NULL else r$time)
  }, numeric(1))
  expect_length(got, 13)
  expect_false(anyNA(got))
  expect_lt(max(abs(got - ex$expected)), 1e-5)
})

test_that("the probability decreases with the margin and is 0 or 1 at the extremes", {
  m <- seq(-0.9, 0.9, by = 0.1)
  p <- .prob_diff("rate", 10.5, 20.5, 8.5, 22.5, m)
  expect_true(all(diff(p) <= 1e-12))
  expect_equal(.prob_diff("rate", 1, 1, 1, 1, c(-0.999999, 0.999999)), c(1, 0),
               tolerance = 1e-6)
  q <- .prob_diff("surv", 12, 300, 15, 280, m, time = 6)
  expect_true(all(diff(q) <= 1e-12))
  # the probability falls from near 1 to near 0 over the range of margins
  expect_gt(q[1], 0.999)
  expect_lt(q[length(q)], 0.001)
})

test_that("swapping the groups gives the complementary probability", {
  # the outer integral is over the posterior with the smaller spread; swapping
  # the groups and reversing the margin uses the other branch of the code
  p1 <- .prob_diff("rate", 20.5, 20.5, 5.5, 35.5, 0.3)
  p2 <- 1 - .prob_diff("rate", 5.5, 35.5, 20.5, 20.5, -0.3)
  expect_equal(p1, p2, tolerance = 1e-7)
  q1 <- .prob_diff("surv", 20.5, 300, 3.5, 40, 0.1, time = 6)
  q2 <- 1 - .prob_diff("surv", 3.5, 40, 20.5, 300, -0.1, time = 6)
  expect_equal(q1, q2, tolerance = 1e-7)
})
