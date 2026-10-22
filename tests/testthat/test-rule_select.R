test_that("the selected cohort follows the rules", {
  r <- data.frame(br_diff = c(0.1, -0.1, 0.2, NA), adm_trt = c(TRUE, TRUE, FALSE, FALSE),
                  adm_ctl = c(TRUE, FALSE, TRUE, FALSE), br_ref = c(0.6, 0.7, 0.2, 0.9),
                  adm_ref = c(TRUE, FALSE, TRUE, TRUE), ntb = c(0.1, NA, -0.1, 0))
  expect_identical(.rule_select(r, "br_diff", 0),
                   c("treatment", "treatment", "control", "none"))
  expect_identical(.rule_select(r, "br_diff", 0, admissibility = FALSE),
                   c("treatment", "control", "treatment", "control"))
  expect_identical(.rule_select(r, "br_ref", 0.5),
                   c("treatment", "control", "control", "treatment"))
  expect_identical(.rule_select(r, "ntb", 0), c("treatment", "control", "control", "control"))
  expect_error(.rule_select(r, "wr", 1), "wr")
})
