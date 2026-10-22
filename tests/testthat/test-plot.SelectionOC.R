test_that("the plotted matrix has one row per threshold and one column per cohort", {
  oc <- SelectionOC(oc_results(), "ntb", threshold = c(0, -1))
  M <- with_null_device(plot(oc))
  expect_identical(dimnames(M), list(c("0", "-1"), c("A", "B", "C")))
  expect_equal(unname(M["-1", ]), c(0, 0.5, 0.5))
  expect_equal(unname(M["0", ]), c(0.75, 0, 0.25))
  # a single threshold gives bars
  M1 <- with_null_device(plot(SelectionOC(oc_results(), "br_diff")))
  expect_identical(colnames(M1), c("A", "B", "C", "(none)"))
  expect_equal(unname(M1[1, ]), c(1, 1, 1, 1) / 4)
  for (p in c("bottom", "top", "right", "none")) {
    M2 <- with_null_device(plot(oc, col = c("red", "blue"), legend.position = p,
                                cex.legend = 1.2, cex.lab = 1.1))
    expect_identical(M2, M)
  }
  expect_identical(with_null_device(plot(oc, threshold = 0.1)), M)
  expect_error(plot(oc, threshold = "a"), "threshold")
  expect_error(plot(oc, cex.lab = c(1, 2)), "cex.lab")
  bad <- structure(data.frame(a = 1), class = c("SelectionOC", "data.frame"))
  expect_error(plot(bad), "SelectionOC")
  both <- rbind(oc, SelectionOC(oc_results(), "wr"))
  expect_error(plot(both), "several statistics")
})
