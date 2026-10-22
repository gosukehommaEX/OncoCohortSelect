test_that("missing admissibility columns give an error only when they are used", {
  r <- data.frame(br_diff = c(0.1, -0.1), br_ref = c(0.6, 0.4), ntb = c(0.1, 0))
  expect_error(.check_adm(r, "br_diff", TRUE), "adm_trt and adm_ctl")
  expect_error(.check_adm(r, "br_ref", TRUE), "adm_ref")
  expect_null(.check_adm(r, "br_diff", FALSE))
  expect_null(.check_adm(r, "ntb", TRUE))
  r$adm_trt <- TRUE
  r$adm_ctl <- FALSE
  expect_null(.check_adm(r, "br_diff", TRUE))
  # the check is applied by SelectionOC() and CalibrateThreshold()
  expect_error(SelectionOC(r, "br_ref", threshold = 0.5), "adm_ref")
  expect_error(CalibrateThreshold(r, "br_ref", alpha = 0.5), "adm_ref")
  expect_equal(SelectionOC(r, "br_ref", threshold = 0.5, admissibility = FALSE)$p_treatment,
               0.5)
})
