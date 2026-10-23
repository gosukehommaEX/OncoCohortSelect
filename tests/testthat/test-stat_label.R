test_that("statistics are described and unknown names are returned as they are", {
  expect_identical(.stat_label("ntb"), "Net treatment benefit against the reference")
  expect_identical(.stat_label("br"), "Benefit-risk score against target values")
  expect_identical(.stat_label("xyz"), "xyz")
})

test_that("short labels have no underscores", {
  stats <- c("br", "br_diff", "br_ref", "ntb", "ntb_lower", "wr", "wo")
  short <- vapply(stats, .stat_label, character(1), short = TRUE)
  expect_false(any(grepl("_", short, fixed = TRUE)))
  expect_identical(unname(short[c("br_diff", "wr")]), c("BR difference", "Win ratio"))
  expect_identical(.stat_label("xyz", short = TRUE), "xyz")
})
