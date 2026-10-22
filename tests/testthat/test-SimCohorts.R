test_that("output structure, cutoff and ordering", {
  d <- SimCohorts(nsim = 3, n = c(20, 15), arms = test_arms(), ae.rate = c(0.3, 0.2),
                  cutoff = 18, a.time = c(0, 12), seed = 11)
  expect_named(d, c("sim", "group", "accrual_time", "pfs_tte", "pfs_event", "os_tte",
                    "os_event", "response", "ae"))
  # all patients are enrolled before the cutoff
  expect_equal(nrow(d), 3 * 35)
  expect_true(all(d$accrual_time >= 0 & d$accrual_time <= 12))
  expect_true(all(d$accrual_time + d$os_tte <= 18 + 1e-9))
  expect_true(all(d$pfs_tte <= d$os_tte + 1e-12))
  expect_true(all(d$ae %in% c(0L, 1L)))
  expect_true(all(d$response %in% c(0L, 1L)))
  expect_identical(d$group, rep(rep(c("Cohort1", "Cohort2"), c(20, 15)), 3))
  expect_identical(d$sim, rep(1:3, each = 35))
})

test_that("the same seed reproduces the data and another seed does not", {
  d1 <- SimCohorts(nsim = 2, n = c(10, 10), arms = test_arms(), ae.rate = c(0.3, 0.2),
                   seed = 1)
  d2 <- SimCohorts(nsim = 2, n = c(10, 10), arms = test_arms(), ae.rate = c(0.3, 0.2),
                   seed = 1)
  d3 <- SimCohorts(nsim = 2, n = c(10, 10), arms = test_arms(), ae.rate = c(0.3, 0.2),
                   seed = 2)
  expect_identical(d1, d2)
  expect_false(identical(d1$pfs_tte, d3$pfs_tte))
})

test_that("the adverse event has the specified rate and is independent of the other endpoints", {
  d <- SimCohorts(nsim = 200, n = c(50, 50), arms = test_arms(), ae.rate = c(0.35, 0.15),
                  seed = 5)
  p <- tapply(d$ae, d$group, mean)
  expect_lt(abs(p[["Cohort1"]] - 0.35), 4 * sqrt(0.35 * 0.65 / 10000))
  expect_lt(abs(p[["Cohort2"]] - 0.15), 4 * sqrt(0.15 * 0.85 / 10000))
  for (g in c("Cohort1", "Cohort2")) {
    s <- d[d$group == g, ]
    expect_lt(abs(stats::cor(s$ae, s$response)), 4 / sqrt(nrow(s)))
    expect_lt(abs(stats::cor(s$ae, rank(s$pfs_tte))), 4 / sqrt(nrow(s)))
  }
})

test_that("cohorts with different accrual are cut at a common calendar time", {
  d <- SimCohorts(nsim = 2, n = c(30, 30), arms = test_arms(), ae.rate = c(0.3, 0.2),
                  cutoff = 20, a.time = list(c(0, 12), c(10, 22)), seed = 3)
  a2 <- d$accrual_time[d$group == "Cohort2"]
  expect_true(all(a2 >= 10 & a2 < 20))
  expect_true(all(d$accrual_time + d$pfs_tte <= 20 + 1e-9))
  expect_lt(sum(d$group == "Cohort2"), 2 * 30)
})

test_that("unnamed cohorts are labeled and invalid arguments give errors", {
  arms <- unname(test_arms())
  d <- SimCohorts(nsim = 1, n = c(5, 5), arms = arms, ae.rate = c(0.3, 0.2), seed = 1)
  expect_identical(unique(d$group), c("Cohort1", "Cohort2"))
  expect_error(SimCohorts(1, c(5, 5), arms = list(1, 2), ae.rate = c(0.3, 0.2)), "OncoArm")
  expect_error(SimCohorts(1, 5, arms = test_arms(), ae.rate = c(0.3, 0.2)), "'n'")
  expect_error(SimCohorts(1, c(5, 5), arms = test_arms(), ae.rate = 0.3), "ae.rate")
  expect_error(SimCohorts(1, c(5, 5), arms = test_arms(), ae.rate = c(0.3, 0.2),
                          cutoff = -1), "cutoff")
  expect_error(SimCohorts(1, c(5, 5), arms = test_arms(), ae.rate = c(0.3, 0.2),
                          a.time = list(c(0, 12))), "a.time")
  expect_error(SimCohorts(0, c(5, 5), arms = test_arms(), ae.rate = c(0.3, 0.2)), "nsim")
})
