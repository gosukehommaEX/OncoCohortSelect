test_that("the cohorts, the levels and the intervals are printed", {
  d <- fixture("gpc_cont.csv")
  w <- WinStat(d, fixture_endpoints(), treatment = "T", control = "C", group = "arm")
  out <- capture.output(v <- withVisible(print(w)))
  expect_false(v$visible)
  expect_identical(v$value, w)
  expect_identical(out[1:2],
                   c("Generalized pairwise comparisons: T (treatment) vs C (control)",
                     "Patients: 40 and 35 (1400 pairs); scoring rule of Gehan"))
  expect_true(any(out == "95% confidence intervals:"))
  expect_true(any(grepl("^Pairs won ", out)))
  wp <- WinStat(d, fixture_endpoints(), treatment = "T", control = "C", group = "arm",
                scoring = "peron", conf.level = 0.9)
  outp <- capture.output(print(wp))
  expect_identical(outp[2], "Patients: 40 and 35 (1400 pairs); scoring rule of Peron")
  expect_true(any(outp == "90% confidence intervals:"))
})
