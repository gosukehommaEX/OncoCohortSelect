test_that("the selected cohort follows the rules (worked out by hand)", {
  r <- oc_results()
  s <- .rule_select(r, "br_diff", 0)
  expect_named(s, c("sim", "selected", "fixed", "max"))
  expect_identical(s$sim, 1:4)
  # 1: B and C exceed 0, C larger; 2: reference not admissible, B admissible;
  # 3: B not admissible, C below 0; 4: no cohort admissible
  expect_identical(s$selected, c("C", "B", "A", NA))
  expect_identical(s$fixed, c(FALSE, TRUE, FALSE, FALSE))
  expect_equal(s$max, c(0.3, -Inf, -0.3, -Inf))
  expect_identical(.rule_select(r, "br_diff", 0.35)$selected, c("A", "B", "A", NA))
  expect_identical(.rule_select(r, "br_diff", 0, admissibility = FALSE)$selected,
                   c("C", "C", "B", "C"))
  expect_identical(.rule_select(r, "br_ref", 0.5)$selected, c("B", "C", "A", "B"))
  expect_identical(.rule_select(r, "br_ref", 0.5, admissibility = FALSE)$selected,
                   c("B", "C", "C", "B"))
  expect_identical(.rule_select(r, "ntb", 0)$selected, c("C", "A", "A", "A"))
  # ties go to the first cohort; a missing statistic is not a candidate
  expect_identical(.rule_select(r, "ntb", -0.15)$selected, c("C", "C", "B", "B"))
  expect_identical(.rule_select(r, "wr", 1)$selected, c("B", "C", "A", "C"))
  expect_error(.rule_select(r, "wo", 1), "wo")
})

test_that("with ref.inadmissible = 'keep' every candidate needs the threshold (by hand)", {
  r <- oc_results()
  s <- .rule_select(r, "br_diff", 0, ref.inadmissible = "keep")
  # 1: B and C exceed 0, C larger; 2: reference not admissible, B admissible
  # but below 0, so A is kept; 3: C admissible but below 0; 4: no other cohort
  # admissible, so A is kept
  expect_identical(s$selected, c("C", "A", "A", "A"))
  expect_identical(s$fixed, rep(FALSE, 4))
  expect_equal(s$max, c(0.3, -0.1, -0.3, -Inf))
  expect_identical(.rule_select(r, "br_diff", -0.2, ref.inadmissible = "keep")$selected,
                   c("C", "B", "A", "A"))
  # the other statistics and the rule without admissibility do not change
  expect_identical(.rule_select(r, "br_diff", 0, admissibility = FALSE,
                                ref.inadmissible = "keep")$selected,
                   c("C", "C", "B", "C"))
  expect_identical(.rule_select(r, "br_ref", 0.5, ref.inadmissible = "keep")$selected,
                   c("B", "C", "A", "B"))
  expect_identical(.rule_select(r, "ntb", 0, ref.inadmissible = "keep")$selected,
                   c("C", "A", "A", "A"))
})
