test_that("valid results pass and invalid results give errors", {
  r <- oc_results()
  expect_null(.check_results(r, "ntb"))
  expect_error(.check_results(r, "wo"), "no column wo")
  expect_error(.check_results(r[, c("sim", "group", "ntb")], "ntb"), "is_reference")
  expect_error(.check_results(r[0, ], "ntb"), "at least one row")
  r2 <- r
  r2$is_reference[2] <- TRUE
  expect_error(.check_results(r2, "ntb"), "exactly one reference")
  r3 <- r
  r3$is_reference[1] <- FALSE
  expect_error(.check_results(r3, "ntb"), "exactly one reference")
  r4 <- r
  r4$is_reference[1] <- NA
  expect_error(.check_results(r4, "ntb"), "missing values")
})
