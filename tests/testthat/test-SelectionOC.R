test_that("selection probabilities follow the decision rules (worked out by hand)", {
  r <- oc_results()
  oc <- SelectionOC(r, "br_diff", threshold = c(0, 0.35))
  expect_named(oc, c("statistic", "threshold", "group", "p_select"))
  expect_identical(oc$threshold, rep(c(0, 0.35), each = 4))
  expect_identical(oc$group, rep(c("A", "B", "C", "(none)"), 2))
  expect_equal(oc$p_select, c(1, 1, 1, 1, 2, 1, 0, 1) / 4)
  oc2 <- SelectionOC(r, "br_diff", threshold = 0, admissibility = FALSE)
  expect_identical(oc2$group, c("A", "B", "C"))
  expect_equal(oc2$p_select, c(0, 1, 3) / 4)
  expect_equal(SelectionOC(r, "br_ref", threshold = 0.5)$p_select, c(1, 2, 1) / 4)
  expect_equal(SelectionOC(r, "ntb")$p_select, c(3, 0, 1) / 4)
  expect_equal(SelectionOC(r, "wr")$p_select, c(1, 1, 2) / 4)
  # the probabilities of each threshold sum to 1
  expect_equal(as.vector(tapply(oc$p_select, oc$threshold, sum)), c(1, 1))
})

test_that("the probabilities agree with the selections of the trials", {
  r <- oc_results()
  for (th in c(-1, 0, 0.15, 1)) {
    sel <- .rule_select(r, "ntb", th)$selected
    oc <- SelectionOC(r, "ntb", threshold = th)
    expect_equal(oc$p_select, vapply(c("A", "B", "C"), function(g) mean(sel == g), 1),
                 ignore_attr = TRUE)
  }
  expect_equal(SelectionOC(r, "ntb", threshold = -1)$p_select, c(0, 2, 2) / 4)
})

test_that("invalid arguments give errors", {
  r <- oc_results()
  expect_error(SelectionOC(r, "br_ref"), "threshold")
  expect_error(SelectionOC(r, "ntb", threshold = NA_real_), "threshold")
  expect_error(SelectionOC(r, "xyz"))
  expect_error(SelectionOC(r, "ntb", admissibility = NA), "admissibility")
  expect_error(SelectionOC(r[, c("sim", "group", "is_reference", "ntb")], "br_diff"),
               "br_diff")
})
