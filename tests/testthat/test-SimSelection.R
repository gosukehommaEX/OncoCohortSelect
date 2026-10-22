sim_criteria <- function() {
  data.frame(endpoint = c("ORR", "PFS", "OS", "AE"), target = c(0.3, 0.5, 0.6, 0.3),
             time = c(NA, 6, 12, NA), cutoff = c(0.2, 0.2, NA, 0.2))
}
sim_criteria_ref <- function() {
  data.frame(endpoint = c("ORR", "PFS", "OS", "AE"), measure = c("rate", "surv", "hr", "rate"),
             target = c(0.1, 0.05, 0.9, 0.1), time = c(NA, 6, NA, NA))
}
three_arms <- function() {
  c(test_arms(),
    list(Cohort3 = CorOncoEndpoints::OncoArm(pfs.median = 7, orr = 0.40, resp.cor = 0.4,
                                             death.prop = 0.15, os.median = 16)))
}

test_that("each row agrees with BenefitRisk() and WinStat() for the same trial", {
  d <- SimCohorts(nsim = 3, n = c(25, 20, 15), arms = three_arms(),
                  ae.rate = c(0.35, 0.2, 0.3), cutoff = 20, a.time = c(0, 12), seed = 3)
  eps <- sim_endpoints()
  pri <- c("OS", "PFS", "ORR", "AE")
  for (sc in c("gehan", "peron")) {
    res <- SimSelection(d, eps, sim_criteria(), reference = "Cohort2",
                        criteria.ref = sim_criteria_ref(), priority = pri,
                        threshold = c(1, 0, 0, 0), scoring = sc, scores = TRUE)
    expect_identical(res$sim, rep(1:3, each = 3))
    expect_identical(res$group, rep(c("Cohort1", "Cohort2", "Cohort3"), 3))
    expect_identical(res$is_reference, rep(c(FALSE, TRUE, FALSE), 3))
    for (s in 1:3) {
      ds <- d[d$sim == s, ]
      b <- BenefitRisk(ds, eps, sim_criteria())
      br <- BenefitRisk(ds, eps, sim_criteria_ref(), reference = "Cohort2")
      for (g in c("Cohort1", "Cohort2", "Cohort3")) {
        i <- which(res$sim == s & res$group == g)
        expect_length(i, 1)
        expect_equal(res$br[i], b$BR[b$group == g], tolerance = 1e-12)
        expect_identical(res$adm[i], b$admissible[b$group == g])
        expect_equal(res[["S:PFS_S6"]][i], b$PFS_S6[b$group == g], tolerance = 1e-12)
        if (g == "Cohort2") {
          expect_true(all(is.na(unlist(res[i, c("br_diff", "br_ref", "adm_ref", "ntb", "wr",
                                                  "ref:OS_HR")]))))
          next
        }
        expect_equal(res$br_diff[i], b$BR[b$group == g] - b$BR[b$group == "Cohort2"],
                     tolerance = 1e-12)
        expect_equal(res$br_ref[i], br$BR[br$group == g], tolerance = 1e-10)
        expect_identical(res$adm_ref[i], br$admissible[br$group == g])
        expect_equal(res[["ref:OS_HR"]][i], br$OS_HR[br$group == g], tolerance = 1e-12)
        w <- WinStat(ds, eps, treatment = g, control = "Cohort2", priority = pri,
                     threshold = c(1, 0, 0, 0), scoring = sc)
        expect_false(anyNA(w$estimate))
        expect_equal(res$ntb[i], w$estimate[["ntb"]], tolerance = 1e-12)
        expect_equal(res$wr[i], w$estimate[["wr"]], tolerance = 1e-12)
        expect_equal(res$p_tie[i], w$estimate[["p_tie"]], tolerance = 1e-12)
        expect_equal(res$ntb_se[i], w$ci$se[1], tolerance = 1e-12)
        expect_equal(res$ntb_lower[i], w$ci$lower[1], tolerance = 1e-12)
      }
    }
  }
})

test_that("the cohorts compared can be chosen", {
  d <- SimCohorts(nsim = 2, n = c(15, 15, 15), arms = three_arms(),
                  ae.rate = c(0.35, 0.2, 0.3), seed = 5)
  res <- SimSelection(d, sim_endpoints(), sim_criteria(), reference = "Cohort3",
                      cohorts = c("Cohort3", "Cohort1"))
  expect_identical(res$group, rep(c("Cohort3", "Cohort1"), 2))
  expect_identical(res$is_reference, rep(c(TRUE, FALSE), 2))
  # the comparison of two cohorts does not depend on the other cohorts
  d2 <- d[d$group != "Cohort2", ]
  res2 <- SimSelection(d2, sim_endpoints(), sim_criteria(), reference = "Cohort3")
  expect_equal(res2$ntb[res2$group == "Cohort1"], res$ntb[res$group == "Cohort1"],
               tolerance = 1e-14)
  expect_false(anyNA(res$ntb[!res$is_reference]))
})

test_that("columns of the reference score are omitted without criteria.ref", {
  d <- SimCohorts(nsim = 2, n = c(15, 15), arms = test_arms(), ae.rate = c(0.35, 0.2),
                  seed = 4)
  res <- SimSelection(d, sim_endpoints(), sim_criteria(), reference = "Cohort2")
  expect_named(res, c("sim", "group", "is_reference", "br", "adm", "br_diff", "p_win",
                      "p_loss", "p_tie", "ntb", "ntb_se", "ntb_lower", "wr", "wo"))
  expect_s3_class(res, c("SimSelection", "data.frame"))
  expect_identical(attr(res, "settings"),
                   list(reference = "Cohort2", scoring = "gehan", conf.level = 0.95))
  expect_equal(nrow(res), 4)
})

test_that("invalid arguments give errors", {
  d <- SimCohorts(nsim = 2, n = c(10, 10), arms = test_arms(), ae.rate = c(0.35, 0.2),
                  seed = 6)
  eps <- sim_endpoints()
  d1 <- d[!(d$sim == 2 & d$group == "Cohort2"), ]
  expect_error(SimSelection(d1, eps, sim_criteria(), reference = "Cohort1"), "every cohort")
  expect_error(SimSelection(d, eps, sim_criteria(), reference = "Cohort9"), "reference")
  expect_error(SimSelection(d, eps, sim_criteria(), reference = "Cohort1",
                            cohorts = c("Cohort1", "Cohort9")), "cohorts")
  expect_error(SimSelection(d, eps, sim_criteria(), reference = "Cohort1",
                            cohorts = "Cohort1"), "two cohorts")
  expect_error(SimSelection(d, eps, sim_criteria(), reference = "Cohort1",
                            scoring = "xyz"))
})
