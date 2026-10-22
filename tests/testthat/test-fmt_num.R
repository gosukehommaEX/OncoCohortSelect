test_that("numbers are formatted without blanks", {
  expect_identical(.fmt_num(c(0.3, 6, 12.5, 0.05, 1 / 3), 4),
                   c("0.3", "6", "12.5", "0.05", "0.3333"))
  expect_identical(.fmt_num(c(-0.0712, 1.4), 2, "f"), c("-0.07", "1.40"))
  expect_identical(.fmt_num(2, 3), "2")
})
