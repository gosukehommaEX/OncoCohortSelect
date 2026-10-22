# Comparison of WinStat() with the BuyseTest package
#
# Run from the package root, after devtools::load_all() or
# library(OncoCohortSelect):
#   source("inst/validation/validate_winstat.R")
# Requires the BuyseTest package. Writes
# inst/validation/output/validate_winstat.csv and
# inst/validation/output/validate_winstat.md (generated, do not edit by hand).
#
# 50 simulated pairs of cohorts (SimCohorts(), analysis at month 24) are
# analyzed by WinStat() and by BuyseTest() with the Gehan scoring rule and
# U-statistic inference, with two priority orders, and with the Peron scoring
# rule (point estimates only, since the standard errors of WinStat() treat the
# Kaplan-Meier estimates as known), with three priority orders, one of which
# uses OS again with a smaller threshold. PASS when the largest absolute
# difference over the 50 trials is within the tolerance. Run time: a few
# minutes.

if (!exists("WinStat")) library(OncoCohortSelect)
if (!requireNamespace("BuyseTest", quietly = TRUE)) {
  stop("The BuyseTest package is required for this script.", call. = FALSE)
}
# BuyseTest is attached so that its S4 methods for coef() and confint() are used
suppressPackageStartupMessages(library(BuyseTest))
message("Using BuyseTest ", utils::packageVersion("BuyseTest"))
out_dir <- file.path("inst", "validation", "output")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

arms <- list(
  Cohort1 = CorOncoEndpoints::OncoArm(pfs.median = 8, orr = 0.45, resp.cor = 0.4,
                                      death.prop = 0.15, os.median = 18),
  Cohort2 = CorOncoEndpoints::OncoArm(pfs.median = 6, orr = 0.30, resp.cor = 0.4,
                                      death.prop = 0.15, os.median = 15))
d <- SimCohorts(nsim = 50, n = c(40, 40), arms = arms, ae.rate = c(0.35, 0.20), cutoff = 24,
                a.time = c(0, 12), seed = 2026)
eps <- list(Endpoint("OS", "tte", time = "os_tte", event = "os_event"),
            Endpoint("PFS", "tte", time = "pfs_tte", event = "pfs_event"),
            Endpoint("ORR", "binary", var = "response"),
            Endpoint("AE", "binary", var = "ae", higher.better = FALSE))
f1 <- arm ~ tte(os_tte, status = os_event) + tte(pfs_tte, status = pfs_event) +
  bin(response) + bin(ae, operator = "<0")
f2 <- arm ~ bin(response) + tte(pfs_tte, status = pfs_event, threshold = 2) +
  bin(ae, operator = "<0") + tte(os_tte, status = os_event, threshold = 1)
f3 <- arm ~ tte(os_tte, status = os_event, threshold = 3) + bin(response) +
  tte(os_tte, status = os_event) + tte(pfs_tte, status = pfs_event, threshold = 1)
specs <- list(
  list(label = "Gehan: OS, PFS, ORR, AE (thresholds 0)", scoring = "gehan",
       priority = c("OS", "PFS", "ORR", "AE"), threshold = c(0, 0, 0, 0), formula = f1),
  list(label = "Gehan: ORR, PFS (threshold 2), AE, OS (threshold 1)", scoring = "gehan",
       priority = c("ORR", "PFS", "AE", "OS"), threshold = c(0, 2, 0, 1), formula = f2),
  list(label = "Peron: OS, PFS, ORR, AE (thresholds 0)", scoring = "peron",
       priority = c("OS", "PFS", "ORR", "AE"), threshold = c(0, 0, 0, 0), formula = f1),
  list(label = "Peron: ORR, PFS (threshold 2), AE, OS (threshold 1)", scoring = "peron",
       priority = c("ORR", "PFS", "AE", "OS"), threshold = c(0, 2, 0, 1), formula = f2),
  list(label = "Peron: OS (threshold 3), ORR, OS, PFS (threshold 1)", scoring = "peron",
       priority = c("OS", "ORR", "OS", "PFS"), threshold = c(3, 0, 0, 1), formula = f3))
last <- function(x) unname(x[length(x)])
rows <- list()
for (sp in specs) {
  gehan <- sp$scoring == "gehan"
  diffs <- t(vapply(1:50, function(s) {
    ds <- d[d$sim == s, ]
    ds$arm <- factor(ds$group, levels = c("Cohort2", "Cohort1"))
    w <- WinStat(ds, eps, treatment = "Cohort1", control = "Cohort2",
                 priority = sp$priority, threshold = sp$threshold, scoring = sp$scoring)
    bt <- BuyseTest(sp$formula, data = ds, scoring.rule = if (gehan) "Gehan" else "Peron",
                    method.inference = if (gehan) "u-statistic" else "none", trace = 0)
    se <- NA_real_
    if (gehan) {
      ci <- confint(bt, statistic = "netBenefit")
      se <- abs(w$ci$se[1] - ci[nrow(ci), "se"])
    }
    c(p_win = abs(w$estimate[["p_win"]] - last(coef(bt, statistic = "favorable"))),
      p_loss = abs(w$estimate[["p_loss"]] - last(coef(bt, statistic = "unfavorable"))),
      wr = abs(w$estimate[["wr"]] - last(coef(bt, statistic = "winRatio"))),
      ntb_se = se)
  }, numeric(4)))
  if (!gehan) diffs <- diffs[, c("p_win", "p_loss", "wr")]
  tol <- c(p_win = 1e-10, p_loss = 1e-10, wr = 1e-10, ntb_se = 1e-8)
  for (v in colnames(diffs)) {
    m <- max(diffs[, v])
    rows[[length(rows) + 1L]] <- data.frame(
      priority = sp$label, quantity = v, max_abs_diff = m, tolerance = tol[[v]],
      judgment = if (m <= tol[[v]]) "PASS" else "FAIL", stringsAsFactors = FALSE)
  }
}
res <- do.call(rbind, rows)
utils::write.csv(res, file.path(out_dir, "validate_winstat.csv"), row.names = FALSE)
md <- c("# Comparison of WinStat() with BuyseTest", "",
        paste0("Generated by inst/validation/validate_winstat.R on ", Sys.Date(),
               " with BuyseTest ", utils::packageVersion("BuyseTest"),
               ": largest absolute difference over 50 simulated trials."), "",
        paste0("Judgments: ", paste(names(table(res$judgment)), table(res$judgment),
                                    sep = " = ", collapse = ", "), "."), "",
        "| Priority | Quantity | Largest difference | Tolerance | Judgment |",
        "|---|---|---|---|---|",
        paste0("| ", res$priority, " | ", res$quantity, " | ",
               formatC(res$max_abs_diff, digits = 3, format = "g"), " | ",
               formatC(res$tolerance, digits = 3, format = "g"), " | ", res$judgment, " |"))
writeLines(md, file.path(out_dir, "validate_winstat.md"))
print(table(res$judgment))
if (any(res$judgment == "FAIL")) warning("Some checks failed.")
