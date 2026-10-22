test_that("the plotted values are the components and the score", {
  d <- fixture("br_data.csv")
  res <- BenefitRisk(d, fixture_endpoints(), fixture("br_criteria_target.csv"))
  M <- with_null_device(plot(res))
  comp <- attr(res, "components")
  expect_identical(dimnames(M), list(c(comp$label, "BR"), res$group))
  expect_equal(M["BR", ], stats::setNames(res$BR, res$group))
  expect_equal(unname(M[comp$label[1], ]), res[[comp$label[1]]])
  res2 <- BenefitRisk(d, fixture_endpoints(), fixture("br_criteria_reference.csv"),
                      reference = "Cohort2")
  M2 <- with_null_device(plot(res2))
  expect_identical(colnames(M2), res2$group)
  expect_error(plot(res[, c("group", "BR")]), "BenefitRisk")
  for (p in c("bottom", "top", "bottomleft", "none")) {
    M3 <- with_null_device(plot(res, col = c("grey80", "black"), legend.position = p,
                                cex.axis = 1.3, cex.legend = 0.7))
    expect_identical(M3, M)
  }
  expect_error(plot(res, cex.legend = -1), "cex.legend")
})
