test_that("component scores use the posterior parameters of each group", {
  d <- data.frame(t = c(2, 5, 7, 10, 4), e = c(1, 0, 1, 1, 1), r = c(1, 0, NA, 1, 0))
  key <- c(1L, 1L, 2L, 2L, 2L)
  eps <- .check_endpoints(list(Endpoint("T", "tte", time = "t", event = "e"),
                               Endpoint("R", var = "r")))
  crit <- .check_criteria(data.frame(endpoint = c("T", "R"), target = c(0.5, 0.4),
                                     time = c(4, NA)), eps, two.sample = FALSE)
  S <- .br_scores(d, eps, crit, key, 2L, trt = 1:2)
  # group 1: 1 event in 7, responders 1 of 2; group 2: 3 events in 21, responders 1 of 2
  expect_equal(S[, "T_S4"], stats::pgamma(-log(0.5) / 4, 0.5 + c(1, 3), rate = c(7, 21)),
               tolerance = 1e-14)
  expect_equal(S[, "R"], stats::pbeta(0.4, 0.5 + c(1, 1), 0.5 + c(1, 1), lower.tail = FALSE),
               tolerance = 1e-14)
  crit2 <- .check_criteria(data.frame(endpoint = c("T", "R"), measure = c("hr", "rate"),
                                      target = c(1, 0)), eps, two.sample = TRUE)
  S2 <- .br_scores(d, eps, crit2, key, 2L, trt = 1L, ref = 2L)
  expect_equal(unname(S2[1, "T_HR"]), PosteriorProb("hr", 1.5, 7, 1, a.ref = 3.5, b.ref = 21),
               tolerance = 1e-14)
  expect_equal(unname(S2[1, "R"]), 0.5, tolerance = 1e-6)
})
