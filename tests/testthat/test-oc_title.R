test_that("the threshold goes to a second line of the title", {
  expect_identical(.oc_title("br_diff", 0.17942), "BR difference\n(threshold 0.1794)")
  expect_identical(.oc_title("wr", 1.5), "Win ratio\n(threshold 1.5)")
  # several thresholds: the name of the statistic only
  expect_identical(.oc_title("ntb", c(0, 0.1)), "Net treatment benefit")
})
