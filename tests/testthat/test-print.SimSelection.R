test_that("the trials, the cohorts and the first rows are printed", {
  r <- oc_results()
  class(r) <- c("SimSelection", "data.frame")
  attr(r, "settings") <- list(reference = "A", scoring = "peron", conf.level = 0.95)
  out <- capture.output(v <- withVisible(print(r, n = 5)))
  expect_false(v$visible)
  expect_identical(v$value, r)
  expect_identical(out[1:3], c("12 rows of results of 4 simulated trials",
                               "Cohorts: A (reference), B, C",
                               "Scoring rule of the pairwise comparisons: Peron"))
  expect_identical(out[length(out)], "# ... with 7 more rows")
  # without the columns of the trials, the rows are printed without a header
  out2 <- capture.output(print(r[, c("group", "ntb")]))
  expect_false(any(grepl("simulated", out2)))
  expect_identical(out2[length(out2)], "# ... with 2 more rows")
})
