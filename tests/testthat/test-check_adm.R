test_that("missing admissibility columns give an error only when they are used", {
  r <- oc_results()[, c("sim", "group", "is_reference", "br_diff", "br_ref", "ntb")]
  expect_error(.check_adm(r, "br_diff", TRUE), "no column adm;")
  expect_error(.check_adm(r, "br_ref", TRUE), "adm_ref")
  expect_null(.check_adm(r, "br_diff", FALSE))
  expect_null(.check_adm(r, "ntb", TRUE))
  r$adm <- TRUE
  expect_null(.check_adm(r, "br_diff", TRUE))
  # the check is applied by SelectionOC() and CalibrateThreshold()
  expect_error(SelectionOC(r, "br_ref", threshold = 0.5), "adm_ref")
  expect_error(CalibrateThreshold(r, "br_ref", alpha = 0.5), "adm_ref")
  expect_equal(SelectionOC(r, "br_ref", threshold = 0.5, admissibility = FALSE)$p_select,
               c(0, 2, 2) / 4)
})
