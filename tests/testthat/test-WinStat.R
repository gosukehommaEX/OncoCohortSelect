test_that("win statistics agree with an independent Python implementation", {
  specs <- fixture("gpc_specs.csv")
  ex <- fixture("gpc_expected.csv")
  lev <- fixture("gpc_expected_levels.csv")
  for (ds in c("ties", "cont")) {
    d <- fixture(paste0("gpc_", ds, ".csv"))
    for (sp in unique(specs$spec)) {
      s <- specs[specs$spec == sp, ]
      res <- WinStat(d, fixture_endpoints(), treatment = "T", control = "C", group = "arm",
                     priority = s$endpoint, threshold = s$threshold)
      e <- ex[ex$dataset == ds & ex$spec == sp, ]
      v <- c("p_win", "p_loss", "p_tie", "ntb", "wr", "wo")
      expect_identical(names(res$estimate), v)
      expect_equal(nrow(e), 1)
      expect_false(anyNA(res$estimate))
      expect_lt(max(abs(res$estimate[v] - unlist(e[v]))), 1e-12)
      expect_lt(abs(res$ci$se[1] - e$ntb_se), 1e-12)
      expect_lt(abs(res$ci$se[2] - e$wr * e$logwr_se), 1e-12)
      l <- lev[lev$dataset == ds & lev$spec == sp, ]
      expect_identical(res$by.endpoint$endpoint, l$endpoint)
      expect_lt(max(abs(c(res$by.endpoint$win - l$win, res$by.endpoint$loss - l$loss))), 1e-12)
      expect_equal(res$by.endpoint$undecided[nrow(l)], unname(res$estimate["p_tie"]),
                   tolerance = 1e-12)
      # the same comparison fails when the expected value is changed by 1e-6
      expect_failure(expect_lt(max(abs(res$estimate[v] - unlist(e[v]) - 1e-6)), 1e-12))
    }
  }
})

test_that("win statistics agree with BuyseTest (Gehan scoring)", {
  # without BuyseTest the test is skipped and the skip is listed in the summary
  skip_if_not_installed("BuyseTest")
  # BuyseTest is attached so that its S4 methods for coef() and confint() are used
  suppressPackageStartupMessages(library(BuyseTest))
  last <- function(x) unname(x[length(x)])
  for (ds in c("ties", "cont")) {
    d <- fixture(paste0("gpc_", ds, ".csv"))
    d <- d[!is.na(d$resp), ]
    d$arm <- factor(d$arm, levels = c("C", "T"))
    # priority OS, PFS, response, adverse event; thresholds 0
    res <- WinStat(d, fixture_endpoints(), treatment = "T", control = "C", group = "arm")
    bt <- BuyseTest(arm ~ tte(os_time, status = os_event) + tte(pfs_time, status = pfs_event) +
                      bin(resp) + bin(ae, operator = "<0"),
                    data = d, scoring.rule = "Gehan", method.inference = "u-statistic",
                    trace = 0)
    expect_equal(res$estimate[["p_win"]], last(coef(bt, statistic = "favorable")),
                 tolerance = 1e-10)
    expect_equal(res$estimate[["p_loss"]], last(coef(bt, statistic = "unfavorable")),
                 tolerance = 1e-10)
    expect_equal(res$estimate[["wr"]], last(coef(bt, statistic = "winRatio")),
                 tolerance = 1e-10)
    ci <- confint(bt, statistic = "netBenefit")
    expect_equal(res$ci$se[1], ci[nrow(ci), "se"], tolerance = 1e-8)
    # response first, then PFS and OS with positive thresholds
    res2 <- WinStat(d, fixture_endpoints(), treatment = "T", control = "C", group = "arm",
                    priority = c("resp", "pfs", "ae", "os"), threshold = c(0, 2, 0, 1))
    bt2 <- BuyseTest(arm ~ bin(resp) + tte(pfs_time, status = pfs_event, threshold = 2) +
                       bin(ae, operator = "<0") + tte(os_time, status = os_event, threshold = 1),
                     data = d, scoring.rule = "Gehan", method.inference = "u-statistic",
                     trace = 0)
    expect_equal(res2$estimate[["p_win"]], last(coef(bt2, statistic = "favorable")),
                 tolerance = 1e-10)
    expect_equal(res2$estimate[["p_loss"]], last(coef(bt2, statistic = "unfavorable")),
                 tolerance = 1e-10)
    ci2 <- confint(bt2, statistic = "netBenefit")
    expect_equal(res2$ci$se[1], ci2[nrow(ci2), "se"], tolerance = 1e-8)
  }
})

test_that("win statistics with the Peron rule agree with the Python implementation", {
  specs <- fixture("gpc_peron_specs.csv")
  ex <- fixture("gpc_peron_expected.csv")
  lev <- fixture("gpc_peron_expected_levels.csv")
  for (ds in c("ties", "cont", "cens")) {
    d <- fixture(paste0("gpc_", ds, ".csv"))
    for (sp in unique(specs$spec)) {
      s <- specs[specs$spec == sp, ]
      res <- WinStat(d, fixture_endpoints(), treatment = "T", control = "C", group = "arm",
                     priority = s$endpoint, threshold = s$threshold, scoring = "peron")
      e <- ex[ex$dataset == ds & ex$spec == sp, ]
      v <- c("p_win", "p_loss", "p_tie", "ntb", "wr")
      expect_equal(nrow(e), 1)
      expect_false(anyNA(res$estimate))
      expect_lt(max(abs(res$estimate[v] - unlist(e[v]))), 1e-12)
      l <- lev[lev$dataset == ds & lev$spec == sp, ]
      expect_identical(res$by.endpoint$endpoint, l$endpoint)
      expect_lt(max(abs(c(res$by.endpoint$win - l$win, res$by.endpoint$loss - l$loss))), 1e-12)
      expect_failure(expect_lt(max(abs(res$estimate[v] - unlist(e[v]) - 1e-6)), 1e-12))
    }
  }
  # with censored data the Peron rule decides more pairs than the Gehan rule
  d <- fixture("gpc_cens.csv")
  g <- WinStat(d, fixture_endpoints(), treatment = "T", control = "C", group = "arm",
               priority = c("os", "pfs"))
  p <- WinStat(d, fixture_endpoints(), treatment = "T", control = "C", group = "arm",
               priority = c("os", "pfs"), scoring = "peron")
  expect_lt(p$estimate[["p_tie"]], g$estimate[["p_tie"]])
})

test_that("win statistics with the Peron rule agree with BuyseTest", {
  # without BuyseTest the test is skipped and the skip is listed in the summary
  skip_if_not_installed("BuyseTest")
  suppressPackageStartupMessages(library(BuyseTest))
  last <- function(x) unname(x[length(x)])
  for (ds in c("cont", "cens")) {
    d <- fixture(paste0("gpc_", ds, ".csv"))
    d$arm <- factor(d$arm, levels = c("C", "T"))
    res <- WinStat(d, fixture_endpoints(), treatment = "T", control = "C", group = "arm",
                   scoring = "peron")
    bt <- BuyseTest(arm ~ tte(os_time, status = os_event) + tte(pfs_time, status = pfs_event) +
                      bin(resp) + bin(ae, operator = "<0"),
                    data = d, scoring.rule = "Peron", method.inference = "none", trace = 0)
    expect_equal(res$estimate[["p_win"]], last(coef(bt, statistic = "favorable")),
                 tolerance = 1e-8)
    expect_equal(res$estimate[["p_loss"]], last(coef(bt, statistic = "unfavorable")),
                 tolerance = 1e-8)
    # OS with a threshold of 2, response, OS with a threshold of 0, PFS
    res2 <- WinStat(d, fixture_endpoints(), treatment = "T", control = "C", group = "arm",
                    priority = c("os", "resp", "os", "pfs"), threshold = c(2, 0, 0, 1),
                    scoring = "peron")
    bt2 <- BuyseTest(arm ~ tte(os_time, status = os_event, threshold = 2) + bin(resp) +
                       tte(os_time, status = os_event) +
                       tte(pfs_time, status = pfs_event, threshold = 1),
                     data = d, scoring.rule = "Peron", method.inference = "none", trace = 0)
    expect_equal(res2$estimate[["p_win"]], last(coef(bt2, statistic = "favorable")),
                 tolerance = 1e-8)
    expect_equal(res2$estimate[["p_loss"]], last(coef(bt2, statistic = "unfavorable")),
                 tolerance = 1e-8)
  }
})

test_that("the output has the documented structure", {
  d <- fixture("gpc_cont.csv")
  res <- WinStat(d, fixture_endpoints(), treatment = "T", control = "C", group = "arm",
                 conf.level = 0.9)
  expect_named(res, c("estimate", "ci", "by.endpoint", "n"))
  expect_named(res$estimate, c("p_win", "p_loss", "p_tie", "ntb", "wr", "wo"))
  expect_identical(res$ci$statistic, c("NTB", "WR", "WO"))
  expect_equal(unname(res$n), c(40, 35, 1400))
  expect_true(all(res$ci$lower < res$ci$estimate & res$ci$estimate < res$ci$upper))
  # the interval of the win odds is that of the net treatment benefit transformed
  expect_equal(res$ci$lower[3], (1 + res$ci$lower[1]) / (1 - res$ci$lower[1]),
               tolerance = 1e-12)
  # a 90% interval is narrower than a 95% interval
  res95 <- WinStat(d, fixture_endpoints(), treatment = "T", control = "C", group = "arm")
  expect_lt(diff(unlist(res$ci[1, c("lower", "upper")])),
            diff(unlist(res95$ci[1, c("lower", "upper")])))
})

test_that("invalid arguments give errors", {
  d <- fixture("gpc_cont.csv")
  eps <- fixture_endpoints()
  expect_error(WinStat(d, eps, "T", "T", group = "arm"), "two different")
  expect_error(WinStat(d, eps, "T", "X", group = "arm"), "both")
  expect_error(WinStat(d, eps, "T", "C", group = "arm", priority = "orr"), "priority")
  expect_error(WinStat(d, eps, "T", "C", group = "arm", threshold = c(0, 0)), "threshold")
  expect_error(WinStat(d, eps, "T", "C", group = "arm", conf.level = 1), "conf.level")
  expect_error(WinStat(d, eps, "T", "C", group = "arm", scoring = "efron"))
})
