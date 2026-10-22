test_that("the probabilities are printed with one row per threshold", {
  oc <- SelectionOC(oc_results(), "ntb", threshold = c(-1, 0))
  out <- capture.output(v <- withVisible(print(oc)))
  expect_false(v$visible)
  expect_identical(v$value, oc)
  expect_identical(out[1:2], c("Probability that the rule selects each cohort",
                               "Statistic: ntb (Net treatment benefit against the reference)"))
  tab <- utils::read.table(text = out[4:6], header = TRUE)
  expect_equal(tab$threshold, c(-1, 0))
  expect_equal(tab$A, c(0, 0.75))
  expect_equal(tab$B, c(0.5, 0))
  expect_equal(tab$C, c(0.5, 0.25))
  # results of two statistics are printed as a data frame
  both <- rbind(oc, SelectionOC(oc_results(), "wr"))
  out2 <- capture.output(print(both))
  expect_false(any(grepl("^Probability", out2)))
  expect_length(out2, 1 + nrow(both))
})
