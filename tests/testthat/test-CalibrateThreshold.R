test_that("the threshold gives the largest selection probability not above alpha", {
  r <- data.frame(ntb = (1:100) / 100)
  ct <- CalibrateThreshold(r, "ntb", alpha = 0.1)
  expect_equal(ct$threshold, 0.90)
  expect_equal(ct$p_treatment, 0.1)
  expect_equal(CalibrateThreshold(r, "ntb", alpha = 0.105)$threshold, 0.90)
  expect_equal(CalibrateThreshold(r, "ntb", alpha = 0.095)$threshold, 0.91)
  # the calibrated threshold reproduces the probability in SelectionOC()
  expect_equal(SelectionOC(r, "ntb", threshold = ct$threshold)$p_treatment, ct$p_treatment)
})

test_that("ties and missing values are handled", {
  r <- data.frame(wr = c(1.1, 1.1, 1.1, 1.2, NaN))
  ct <- CalibrateThreshold(r, "wr", alpha = 0.5)
  # at most 2 of 5 trials may select the treatment cohort
  expect_equal(ct$threshold, 1.1)
  expect_equal(ct$p_treatment, 1 / 5)
  expect_equal(CalibrateThreshold(r, "wr", alpha = 0.99)$threshold, -Inf)
})

test_that("trials selected whatever the threshold are counted (admissibility)", {
  r <- data.frame(br_diff = c(0.5, 0.4, 0.3, 0.2, 0.1, 0, -0.1, -0.2, 0.9, NA),
                  adm_trt = c(rep(TRUE, 8), TRUE, FALSE),
                  adm_ctl = c(rep(TRUE, 8), FALSE, FALSE))
  ct <- CalibrateThreshold(r, "br_diff", alpha = 0.3)
  # trial 9 always selects the treatment cohort, so 2 of the 8 comparable trials may
  expect_equal(ct$threshold, 0.3)
  expect_equal(ct$p_treatment, 0.3)
  expect_warning(ct2 <- CalibrateThreshold(r, "br_diff", alpha = 0.05), "exceed")
  expect_true(is.na(ct2$threshold))
  expect_equal(ct2$p_treatment, 0.1)
  ct3 <- CalibrateThreshold(r, "br_diff", alpha = 0.05, admissibility = FALSE)
  expect_equal(ct3$threshold, 0.9)
  expect_equal(ct3$p_treatment, 0)
})

test_that("invalid arguments give errors", {
  r <- data.frame(ntb = (1:10) / 10)
  expect_error(CalibrateThreshold(r, "ntb", alpha = 0), "alpha")
  expect_error(CalibrateThreshold(r, "wr", alpha = 0.1), "wr")
  expect_error(CalibrateThreshold(r[0, , drop = FALSE], "ntb"), "at least one row")
})
