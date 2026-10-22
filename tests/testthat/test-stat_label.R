test_that("statistics are described and unknown names are returned as they are", {
  expect_identical(.stat_label("ntb"), "Net treatment benefit against the reference")
  expect_identical(.stat_label("br"), "Benefit-risk score against target values")
  expect_identical(.stat_label("xyz"), "xyz")
})
