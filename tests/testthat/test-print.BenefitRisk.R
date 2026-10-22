test_that("the components and the selected cohort are printed", {
  d <- fixture("br_data.csv")
  res <- BenefitRisk(d, fixture_endpoints(), fixture("br_criteria_target.csv"))
  out <- capture.output(v <- withVisible(print(res)))
  expect_false(v$visible)
  expect_identical(v$value, res)
  expect_identical(out[1], "Posterior benefit-risk scores against target values")
  comp <- attr(res, "components")
  expect_gt(nrow(comp), 0)
  for (k in seq_len(nrow(comp))) {
    expect_true(any(grepl(comp$definition[k], out, fixed = TRUE)))
  }
  sel <- res$group[res$selected]
  expect_identical(out[length(out)],
                   paste0("Selected: ", if (length(sel)) sel else "none (no cohort is admissible)"))
  # rows without the selected cohort
  sub <- res[!res$selected, ]
  expect_identical(capture.output(print(sub))[1], out[1])
  expect_identical(utils::tail(capture.output(print(sub)), 1),
                   if (any(sub$admissible)) "Selected: none of the cohorts shown" else
                     "Selected: none (no cohort is admissible)")
  # relative to a reference cohort
  res2 <- BenefitRisk(d, fixture_endpoints(), fixture("br_criteria_reference.csv"),
                      reference = "Cohort2")
  out2 <- capture.output(print(res2))
  expect_identical(out2[1], "Posterior benefit-risk scores relative to Cohort2")
  expect_false(any(grepl("^Selected", out2)))
  # a subset of the columns is printed as a data frame
  out3 <- capture.output(print(res[, c("group", "BR")]))
  expect_false(any(grepl("Posterior", out3)))
  expect_true(any(grepl("Cohort1", out3)))
})
