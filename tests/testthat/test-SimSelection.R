sim_criteria <- function() {
  data.frame(endpoint = c("ORR", "PFS", "OS", "AE"), target = c(0.3, 0.5, 0.6, 0.3),
             time = c(NA, 6, 12, NA), cutoff = c(0.2, 0.2, NA, 0.2))
}
sim_criteria_ref <- function() {
  data.frame(endpoint = c("ORR", "PFS", "OS", "AE"), measure = c("rate", "surv", "hr", "rate"),
             target = c(0.1, 0.05, 0.9, 0.1), time = c(NA, 6, NA, NA))
}

test_that("each row agrees with BenefitRisk() and WinStat() for the same trial", {
  d <- SimCohorts(nsim = 3, n = c(25, 25), arms = test_arms(), ae.rate = c(0.35, 0.2),
                  cutoff = 20, a.time = c(0, 12), seed = 3)
  eps <- sim_endpoints()
  res <- SimSelection(d, eps, sim_criteria(), treatment = "Cohort1", control = "Cohort2",
                      criteria.ref = sim_criteria_ref(), priority = c("OS", "PFS", "ORR", "AE"),
                      threshold = c(1, 0, 0, 0), scores = TRUE)
  expect_identical(res$sim, 1:3)
  for (s in 1:3) {
    ds <- d[d$sim == s, ]
    b <- BenefitRisk(ds, eps, sim_criteria())
    expect_equal(res$br_trt[s], b$BR[b$group == "Cohort1"], tolerance = 1e-12)
    expect_equal(res$br_ctl[s], b$BR[b$group == "Cohort2"], tolerance = 1e-12)
    expect_identical(res$adm_trt[s], b$admissible[b$group == "Cohort1"])
    expect_identical(res$adm_ctl[s], b$admissible[b$group == "Cohort2"])
    expect_equal(res[["trt:PFS_S6"]][s], b$PFS_S6[b$group == "Cohort1"], tolerance = 1e-12)
    br <- BenefitRisk(ds, eps, sim_criteria_ref(), reference = "Cohort2")
    expect_equal(res$br_ref[s], br$BR, tolerance = 1e-10)
    expect_identical(res$adm_ref[s], br$admissible)
    expect_equal(res[["ref:OS_HR"]][s], br$OS_HR, tolerance = 1e-12)
    w <- WinStat(ds, eps, treatment = "Cohort1", control = "Cohort2",
                 priority = c("OS", "PFS", "ORR", "AE"), threshold = c(1, 0, 0, 0))
    expect_equal(res$ntb[s], w$estimate[["ntb"]], tolerance = 1e-12)
    expect_equal(res$wr[s], w$estimate[["wr"]], tolerance = 1e-12)
    expect_equal(res$ntb_se[s], w$ci$se[1], tolerance = 1e-12)
    expect_equal(res$ntb_lower[s], w$ci$lower[1], tolerance = 1e-12)
  }
  expect_equal(res$br_diff, res$br_trt - res$br_ctl, tolerance = 1e-14)
})

test_that("columns of the reference score are omitted without criteria.ref", {
  d <- SimCohorts(nsim = 2, n = c(15, 15), arms = test_arms(), ae.rate = c(0.35, 0.2),
                  seed = 4)
  res <- SimSelection(d, sim_endpoints(), sim_criteria(), "Cohort1", "Cohort2")
  expect_named(res, c("sim", "br_trt", "br_ctl", "adm_trt", "adm_ctl", "br_diff", "p_win",
                      "p_loss", "p_tie", "ntb", "ntb_se", "ntb_lower", "wr", "wo"))
})

test_that("a trial without one of the cohorts gives an error", {
  d <- SimCohorts(nsim = 2, n = c(10, 10), arms = test_arms(), ae.rate = c(0.35, 0.2),
                  seed = 6)
  d <- d[!(d$sim == 2 & d$group == "Cohort2"), ]
  expect_error(SimSelection(d, sim_endpoints(), sim_criteria(), "Cohort1", "Cohort2"),
               "both")
  expect_error(SimSelection(d, sim_endpoints(), sim_criteria(), "Cohort1", "Cohort1"),
               "two different")
})
