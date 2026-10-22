test_that("statistics and variances agree with values computed by hand", {
  # 2 x 2 pairs: one win and one loss
  pairs <- list(win = matrix(c(TRUE, FALSE, FALSE, FALSE), 2, 2),
                loss = matrix(c(FALSE, FALSE, TRUE, FALSE), 2, 2))
  st <- .gpc_stats(pairs)
  expect_equal(unname(st[c("p_win", "p_loss", "p_tie", "ntb", "wr", "wo")]),
               c(0.25, 0.25, 0.5, 0, 1, 1))
  # Var(p_win) = Var(p_loss) = 1/16, covariance 0 (worked out by hand)
  expect_equal(st[["ntb_se"]], sqrt(1 / 8), tolerance = 1e-14)
  expect_equal(st[["logwr_se"]], sqrt(2), tolerance = 1e-14)
  z <- stats::qnorm(0.975)
  expect_equal(unname(st[c("ntb_lower", "ntb_upper")]), tanh(c(-1, 1) * z * sqrt(1 / 8)),
               tolerance = 1e-14)
  expect_equal(unname(st[c("wr_lower", "wr_upper")]), exp(c(-1, 1) * z * sqrt(2)),
               tolerance = 1e-14)
})

test_that("degenerate cases give missing intervals", {
  all_win <- list(win = matrix(TRUE, 2, 3), loss = matrix(FALSE, 2, 3))
  st <- .gpc_stats(all_win)
  expect_equal(st[["ntb"]], 1)
  expect_true(is.infinite(st[["wr"]]))
  expect_true(all(is.na(st[c("ntb_lower", "ntb_upper", "wr_lower", "wr_upper")])))
  no_pair <- list(win = matrix(FALSE, 2, 2), loss = matrix(FALSE, 2, 2))
  st0 <- .gpc_stats(no_pair)
  expect_true(is.nan(st0[["wr"]]))
  expect_equal(st0[["p_tie"]], 1)
})
