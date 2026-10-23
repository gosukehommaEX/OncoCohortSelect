test_that("the default labels of the components are shown without underscores", {
  comp <- data.frame(
    label = c("ORR", "PFS_S6", "OS_HR", "PFS_S6.1", "my_label", "OS_S12.5", "PFS S(9)"),
    endpoint = c("ORR", "PFS", "OS", "PFS", "ORR", "OS", "PFS"),
    definition = c("P(rate >= 0.3)", "P(S(6) >= 0.5)", "P(HR <= 0.8)", "P(S(6) >= 0.6)",
                   "P(rate >= 0.2)", "P(S(12.5) - reference S(12.5) >= 0.1)",
                   "P(S(9) >= 0.4)"),
    stringsAsFactors = FALSE)
  expect_identical(.display_labels(comp),
                   c("ORR", "PFS S(6)", "OS HR", "PFS S6.1", "my label", "OS S(12.5)",
                     "PFS S(9)"))
})

test_that("the labels of BenefitRisk() are shown without underscores", {
  d <- fixture("br_data.csv")
  res <- BenefitRisk(d, fixture_endpoints(), fixture("br_criteria_target.csv"))
  comp <- attr(res, "components")
  shown <- .display_labels(comp)
  expect_length(shown, nrow(comp))
  expect_false(any(grepl("_", shown, fixed = TRUE)))
  res2 <- BenefitRisk(d, fixture_endpoints(), fixture("br_criteria_reference.csv"),
                      reference = "Cohort2")
  expect_false(any(grepl("_", .display_labels(attr(res2, "components")), fixed = TRUE)))
})
