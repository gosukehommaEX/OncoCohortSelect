test_that("scores against target values agree with independent Python values", {
  d <- fixture("br_data.csv")
  res <- BenefitRisk(d, fixture_endpoints(), fixture("br_criteria_target.csv"))
  ex <- fixture("br_expected_scores.csv")
  ex <- ex[ex$mode == "target", ]
  got <- mapply(function(g, l) res[res$group == g, l], ex$group, ex$label)
  expect_length(got, 12)
  expect_false(anyNA(got))
  expect_lt(max(abs(got - ex$S)), 1e-9)
  sm <- fixture("br_expected_summary.csv")
  sm <- sm[sm$mode == "target", ]
  expect_identical(res$group, sm$group)
  expect_lt(max(abs(res$BR - sm$BR)), 1e-9)
  expect_identical(res$admissible, sm$admissible)
  expect_identical(res$selected, as.logical(sm$selected))
  # the same comparison fails when one expected value is changed by 1e-6
  changed <- ex$S
  changed[2] <- changed[2] + 1e-6
  expect_failure(expect_lt(max(abs(got - changed)), 1e-9))
})

test_that("scores relative to a reference cohort agree with independent Python values", {
  d <- fixture("br_data.csv")
  res <- BenefitRisk(d, fixture_endpoints(), fixture("br_criteria_reference.csv"),
                     reference = "Cohort2")
  ex <- fixture("br_expected_scores.csv")
  ex <- ex[ex$mode == "reference", ]
  got <- mapply(function(g, l) res[res$group == g, l], ex$group, ex$label)
  expect_length(got, 8)
  expect_false(anyNA(got))
  expect_lt(max(abs(got - ex$S)), 1e-5)
  sm <- fixture("br_expected_summary.csv")
  sm <- sm[sm$mode == "reference", ]
  expect_identical(res$group, sm$group)
  expect_identical(res$reference, rep("Cohort2", 2))
  expect_lt(max(abs(res$BR - sm$BR)), 1e-5)
  expect_identical(res$admissible, sm$admissible)
  expect_false("selected" %in% names(res))
})

test_that("the composite score is the weighted geometric mean of the components", {
  d <- fixture("br_data.csv")
  crit <- data.frame(endpoint = c("resp", "pfs", "ae", "ae"), target = c(0.3, 0.5, 0.3, 0.4),
                     time = c(NA, 6, NA, NA))
  res <- BenefitRisk(d, fixture_endpoints(), crit)
  S <- as.matrix(res[, c("resp", "pfs_S6", "ae", "ae.1")])
  expect_equal(res$BR, unname(apply(S, 1, prod) ^ (1 / 4)), tolerance = 1e-12)
  # weights of Chakraborty et al.: efficacy and safety geometric means multiplied
  crit$weight <- c(1 / 2, 1 / 2, 1 / 2, 1 / 2)
  res2 <- BenefitRisk(d, fixture_endpoints(), crit)
  expect_equal(res2$BR, unname(sqrt(S[, 1] * S[, 2]) * sqrt(S[, 3] * S[, 4])),
               tolerance = 1e-12)
  expect_true(all(res2$admissible))
})

test_that("components follow the definitions with one cohort", {
  d <- data.frame(group = "A", t = c(2, 5, 7, 10), e = c(1, 0, 1, 1), r = c(1, 0, NA, 1))
  eps <- list(Endpoint("T", "tte", time = "t", event = "e"),
              Endpoint("R", "binary", var = "r"))
  crit <- data.frame(endpoint = c("T", "R"), target = c(0.6, 0.5), time = c(3, NA),
                     prior.a = c(1, 1), prior.b = c(2, 1), cutoff = c(0.1, 0.9))
  res <- BenefitRisk(d, eps, crit)
  # 3 events in 24 time units; 2 responders among 3 patients with a value
  s_t <- stats::pgamma(-log(0.6) / 3, 1 + 3, rate = 2 + 24)
  s_r <- stats::pbeta(0.5, 1 + 2, 1 + 1, lower.tail = FALSE)
  expect_equal(res$T_S3, s_t, tolerance = 1e-12)
  expect_equal(res$R, s_r, tolerance = 1e-12)
  expect_equal(res$admissible, s_t >= 0.1 && s_r >= 0.9)
  expect_identical(res$selected, res$admissible)
})

test_that("factor groups keep the order of their levels", {
  d <- fixture("br_data.csv")
  d$group <- factor(d$group, levels = c("Cohort3", "Cohort1", "Cohort2"))
  res <- BenefitRisk(d, fixture_endpoints(), fixture("br_criteria_target.csv"))
  expect_identical(res$group, c("Cohort3", "Cohort1", "Cohort2"))
})

test_that("invalid arguments give errors", {
  d <- fixture("br_data.csv")
  eps <- fixture_endpoints()
  crit <- fixture("br_criteria_target.csv")
  expect_error(BenefitRisk(d, eps, crit, group = "arm"), "group")
  expect_error(BenefitRisk(d, eps, crit, reference = "Cohort9"), "reference")
  expect_error(BenefitRisk(d, eps, fixture("br_criteria_reference.csv")), "reference")
  crit$endpoint[1] <- "orr"
  expect_error(BenefitRisk(d, eps, crit), "endpoint")
  expect_error(BenefitRisk(as.list(d), eps, crit), "data frame")
})
