test_that("binary endpoints are scored by hand-checked rules", {
  xt <- data.frame(r = c(1, 0, NA))
  xc <- data.frame(r = c(0, 1))
  s <- .gpc_score(xt, xc, Endpoint("R", var = "r"))
  expect_identical(s$win, matrix(c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE), 3, 2))
  expect_identical(s$loss, matrix(c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE), 3, 2))
  s2 <- .gpc_score(xt, xc, Endpoint("R", var = "r", higher.better = FALSE))
  expect_identical(s2$win, s$loss)
  expect_identical(s2$loss, s$win)
})

test_that("time-to-event endpoints follow the rule of Gehan", {
  # treatment: event at 5, censored at 5, event at 9; control: event at 5, censored at 7
  xt <- data.frame(t = c(5, 5, 9), e = c(1, 0, 1))
  xc <- data.frame(t = c(5, 7), e = c(1, 0))
  ep <- Endpoint("T", "tte", time = "t", event = "e")
  s <- .gpc_score(xt, xc, ep, 0)
  # (event 5, event 5): tie; (event 5, censored 7): loss; (censored 5, event 5): win;
  # (censored 5, censored 7): undecided; (event 9, event 5): win; (event 9, censored 7): undecided
  expect_identical(s$win, matrix(c(FALSE, TRUE, TRUE, FALSE, FALSE, FALSE), 3, 2))
  expect_identical(s$loss, matrix(c(FALSE, FALSE, FALSE, TRUE, FALSE, FALSE), 3, 2))
  # threshold 4: (event 9, event 5) is a win (difference 4); (event 5, censored 7) is undecided
  s4 <- .gpc_score(xt, xc, ep, 4)
  expect_identical(s4$win, matrix(c(FALSE, FALSE, TRUE, FALSE, FALSE, FALSE), 3, 2))
  expect_false(any(s4$loss))
  # threshold 5: no pair is decided
  s5 <- .gpc_score(xt, xc, ep, 5)
  expect_false(any(s5$win | s5$loss))
  # shorter times favorable: wins and losses are exchanged
  s_low <- .gpc_score(xt, xc, Endpoint("T", "tte", time = "t", event = "e",
                                        higher.better = FALSE), 0)
  expect_identical(s_low$win, s$loss)
  expect_identical(s_low$loss, s$win)
})
