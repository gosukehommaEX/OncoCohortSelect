# Results of SimSelection() for four simulated trials of three cohorts, with
# reference cohort A. The selections expected in the tests were worked out by
# hand from these values.
oc_results <- function() {
  data.frame(sim = rep(1:4, each = 3), group = rep(c("A", "B", "C"), 4),
             is_reference = rep(c(TRUE, FALSE, FALSE), 4),
             br_diff = c(NA, 0.1, 0.3, NA, -0.1, 0.2, NA, 0.2, -0.3, NA, NA, 0.1),
             adm = c(TRUE, TRUE, TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, TRUE,
                     FALSE, FALSE, FALSE),
             br_ref = c(NA, 0.6, 0.4, NA, 0.7, 0.8, NA, 0.2, 0.9, NA, 0.9, 0.1),
             adm_ref = c(NA, TRUE, TRUE, NA, FALSE, TRUE, NA, TRUE, FALSE, NA, TRUE, FALSE),
             ntb = c(NA, 0.1, 0.2, NA, NA, -0.1, NA, -0.1, -0.2, NA, 0, 0),
             wr = c(NA, 1.3, NaN, NA, 0.9, 1.2, NA, NaN, NaN, NA, 1, 1.5),
             stringsAsFactors = FALSE)
}

# Results with one cohort B compared with the reference cohort A in each
# simulated trial; 'x' gives the values of 'statistic' for cohort B.
two_cohort_results <- function(x, statistic, adm_b = NULL, adm_a = NULL) {
  n <- length(x)
  r <- data.frame(sim = rep(seq_len(n), each = 2), group = rep(c("A", "B"), n),
                  is_reference = rep(c(TRUE, FALSE), n), stringsAsFactors = FALSE)
  r[[statistic]] <- c(rbind(NA, x))
  if (!is.null(adm_b)) r$adm <- c(rbind(adm_a, adm_b))
  r
}
