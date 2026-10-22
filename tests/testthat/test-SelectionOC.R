oc_results <- function() {
  data.frame(br_diff = c(0.2, -0.1, 0.05, 0.3, NA),
             adm_trt = c(TRUE, TRUE, FALSE, TRUE, FALSE),
             adm_ctl = c(TRUE, TRUE, TRUE, FALSE, FALSE),
             br_ref = c(0.8, 0.4, 0.9, 0.7, 0.2),
             adm_ref = c(TRUE, TRUE, FALSE, TRUE, TRUE),
             ntb = c(0.1, -0.2, 0.05, 0.3, 0),
             ntb_lower = c(-0.1, -0.4, -0.2, 0.05, -0.3),
             wr = c(1.3, 0.6, 1.1, 2, NaN),
             wo = c(1.2, 0.7, 1.1, 1.8, 1))
}

test_that("selection probabilities follow the decision rules (computed by hand)", {
  r <- oc_results()
  oc <- SelectionOC(r, "br_diff", threshold = c(0, 0.25))
  expect_equal(oc$p_treatment, c(2, 1) / 5)
  expect_equal(oc$p_control, c(2, 3) / 5)
  expect_equal(oc$p_none, c(1, 1) / 5)
  oc2 <- SelectionOC(r, "br_diff", threshold = 0, admissibility = FALSE)
  expect_equal(unlist(oc2[, c("p_treatment", "p_control", "p_none")]),
               c(p_treatment = 3, p_control = 2, p_none = 0) / 5)
  expect_equal(SelectionOC(r, "br_ref", threshold = 0.5)$p_treatment, 2 / 5)
  expect_equal(SelectionOC(r, "br_ref", threshold = 0.5, admissibility = FALSE)$p_treatment,
               3 / 5)
  expect_equal(SelectionOC(r, "ntb")$p_treatment, 3 / 5)
  expect_equal(SelectionOC(r, "ntb_lower")$p_treatment, 1 / 5)
  # the missing win ratio selects the control cohort
  expect_equal(SelectionOC(r, "wr")$p_treatment, 3 / 5)
  expect_equal(SelectionOC(r, "wr")$p_control, 2 / 5)
  expect_equal(SelectionOC(r, "wo", threshold = 1.5)$p_treatment, 1 / 5)
})

test_that("the output has one row per threshold", {
  oc <- SelectionOC(oc_results(), "ntb", threshold = c(-1, 0, 1))
  expect_named(oc, c("statistic", "threshold", "p_treatment", "p_control", "p_none"))
  expect_equal(oc$threshold, c(-1, 0, 1))
  expect_equal(oc$p_treatment, c(1, 3 / 5, 0))
})

test_that("invalid arguments give errors", {
  r <- oc_results()
  expect_error(SelectionOC(r, "br_ref"), "threshold")
  expect_error(SelectionOC(r, "ntb", threshold = NA_real_), "threshold")
  expect_error(SelectionOC(r, "xyz"))
  expect_error(SelectionOC(r[, c("ntb", "wr")], "br_diff"), "br_diff")
})
