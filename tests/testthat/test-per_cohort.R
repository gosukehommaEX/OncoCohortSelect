test_that("arguments are expanded to one element per cohort", {
  expect_identical(.per_cohort(NULL, 2, "a"), list(NULL, NULL))
  expect_identical(.per_cohort(c(0, 12), 2, "a"), list(c(0, 12), c(0, 12)))
  expect_identical(.per_cohort(list(1, 2), 2, "a"), list(1, 2))
  expect_error(.per_cohort(list(1), 2, "a.time"), "a.time")
})
