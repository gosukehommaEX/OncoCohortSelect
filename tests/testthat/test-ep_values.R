test_that("values are coded as 1, 0 and NA, and events come from censoring indicators", {
  d <- data.frame(bor = c("CR", "PR", "SD", NA, "NE"), fl = c("Y", "", "Y", "N", ""),
                  r = c(1, 0, NA, 1, 0), t = c(1, 2, 3, 4, 5), cn = c(0, 1, 0, 2, 1),
                  e = c(1, 0, 1, 0, 0), stringsAsFactors = FALSE)
  orr <- Endpoint("ORR", var = "bor", positive = c("CR", "PR"))
  expect_identical(.ep_values(d, orr)$value, c(1, 1, 0, NA, 0))
  expect_identical(.ep_values(d, Endpoint("AE", var = "fl", positive = "Y"))$value,
                   c(1, 0, 1, 0, 0))
  expect_identical(.ep_values(d, Endpoint("R", var = "r"))$value, c(1, 0, NA, 1, 0))
  v <- .ep_values(d, Endpoint("T", "tte", time = "t", censor = "cn"))
  expect_identical(v$time, c(1, 2, 3, 4, 5))
  expect_identical(v$event, c(1, 0, 1, 0, 0))
  expect_identical(.ep_values(d, Endpoint("T", "tte", time = "t", event = "e")), v)
  # a factor column gives the same values
  d$bor <- factor(d$bor)
  expect_identical(.ep_values(d, orr)$value, c(1, 1, 0, NA, 0))
})
