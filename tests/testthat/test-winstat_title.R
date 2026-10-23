test_that("the title gives the NTB and the WR on two lines", {
  d <- fixture("gpc_cont.csv")
  w <- WinStat(d, fixture_endpoints(), treatment = "T", control = "C", group = "arm")
  ci <- w$ci
  f2 <- function(v) sprintf("%.2f", v)
  expected <- paste0("NTB ", f2(ci$estimate[1]), " (95% CI ", f2(ci$lower[1]), " to ",
                     f2(ci$upper[1]), ")\nWR ", f2(ci$estimate[2]), " (95% CI ",
                     f2(ci$lower[2]), " to ", f2(ci$upper[2]), ")")
  expect_identical(.winstat_title(w), expected)
  # without a confidence interval or a confidence level
  x <- list(ci = data.frame(estimate = c(0.1, 1.5), lower = c(NA, 1.1), upper = c(NA, 2)))
  expect_identical(.winstat_title(x), "NTB 0.10\nWR 1.50 (CI 1.10 to 2.00)")
})
