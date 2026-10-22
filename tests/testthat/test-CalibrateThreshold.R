test_that("the threshold gives the largest selection probability not above alpha", {
  r <- two_cohort_results((1:100) / 100, "ntb")
  ct <- CalibrateThreshold(r, "ntb", alpha = 0.1)
  expect_named(ct, c("statistic", "alpha", "threshold", "p_nonreference"))
  expect_equal(ct$threshold, 0.90)
  expect_equal(ct$p_nonreference, 0.1)
  expect_equal(CalibrateThreshold(r, "ntb", alpha = 0.105)$threshold, 0.90)
  expect_equal(CalibrateThreshold(r, "ntb", alpha = 0.095)$threshold, 0.91)
  # the calibrated threshold reproduces the probability in SelectionOC()
  oc <- SelectionOC(r, "ntb", threshold = ct$threshold)
  expect_equal(oc$p_select[oc$group == "B"], ct$p_nonreference)
})

test_that("with several cohorts the largest statistic of each trial is used", {
  r <- data.frame(sim = rep(1:10, each = 3), group = rep(c("A", "B", "C"), 10),
                  is_reference = rep(c(TRUE, FALSE, FALSE), 10),
                  ntb = c(rbind(NA, (1:10) / 10, (10:1) / 10)))
  # largest values by trial: 1, 0.9, 0.8, 0.7, 0.6, 0.6, 0.7, 0.8, 0.9, 1
  ct <- CalibrateThreshold(r, "ntb", alpha = 0.2)
  expect_equal(ct$threshold, 0.9)
  expect_equal(ct$p_nonreference, 0.2)
  # a third trial cannot be added because of the tie at 0.9
  ct2 <- CalibrateThreshold(r, "ntb", alpha = 0.3)
  expect_equal(ct2$threshold, 0.9)
  expect_equal(ct2$p_nonreference, 0.2)
  oc <- SelectionOC(r, "ntb", threshold = ct$threshold)
  expect_equal(sum(oc$p_select[oc$group != "A"]), ct$p_nonreference)
})

test_that("ties and missing values are handled", {
  r <- two_cohort_results(c(1.1, 1.1, 1.1, 1.2, NaN), "wr")
  ct <- CalibrateThreshold(r, "wr", alpha = 0.5)
  # at most 2 of 5 trials may select cohort B
  expect_equal(ct$threshold, 1.1)
  expect_equal(ct$p_nonreference, 1 / 5)
  expect_equal(CalibrateThreshold(r, "wr", alpha = 0.99)$threshold, -Inf)
})

test_that("trials selected whatever the threshold are counted (admissibility)", {
  r <- two_cohort_results(c(0.5, 0.4, 0.3, 0.2, 0.1, 0, -0.1, -0.2, 0.9, NA), "br_diff",
                          adm_b = c(rep(TRUE, 8), TRUE, FALSE),
                          adm_a = c(rep(TRUE, 8), FALSE, FALSE))
  ct <- CalibrateThreshold(r, "br_diff", alpha = 0.3)
  # trial 9 always selects cohort B, so 2 of the 8 comparable trials may
  expect_equal(ct$threshold, 0.3)
  expect_equal(ct$p_nonreference, 0.3)
  expect_warning(ct2 <- CalibrateThreshold(r, "br_diff", alpha = 0.05), "exceed")
  expect_true(is.na(ct2$threshold))
  expect_equal(ct2$p_nonreference, 0.1)
  ct3 <- CalibrateThreshold(r, "br_diff", alpha = 0.05, admissibility = FALSE)
  expect_equal(ct3$threshold, 0.9)
  expect_equal(ct3$p_nonreference, 0)
})

test_that("invalid arguments give errors", {
  r <- two_cohort_results((1:10) / 10, "ntb")
  expect_error(CalibrateThreshold(r, "ntb", alpha = 0), "alpha")
  expect_error(CalibrateThreshold(r, "wr", alpha = 0.1), "wr")
  expect_error(CalibrateThreshold(r[0, ], "ntb"), "at least one row")
})
