#' Print and plot the results of simulated trials
#'
#' @description
#' \code{print()} shows the number of simulated trials, the cohorts and the
#' first rows of the results. \code{plot()} draws the distribution of one
#' statistic over the simulated trials as a box plot for each cohort, with an
#' optional threshold of a decision rule.
#'
#' @param x Data frame returned by \code{\link{SimSelection}}.
#' @param n Number of rows printed.
#' @param digits Number of significant digits.
#' @param statistic The statistic plotted: \code{"ntb"}, \code{"ntb_lower"},
#'   \code{"wr"}, \code{"wo"}, \code{"br_diff"}, \code{"br_ref"} or \code{"br"}
#'   (the score against target values, plotted for every cohort including the
#'   reference).
#' @param threshold Optional threshold drawn as a dashed line.
#' @param col Colors of the cohorts (recycled), in the order of the cohorts in
#'   \code{x}; a cohort keeps its color whatever the statistic.
#' @param main Title of the plot.
#' @param cex.main,cex.lab,cex.axis Sizes of the title, of the axis titles and
#'   of the axis labels, relative to the default size.
#' @param ... Not used.
#' @return \code{print()} returns \code{x} invisibly. \code{plot()} returns
#'   invisibly a list with the plotted values for each cohort; infinite win
#'   ratios or win odds (no pair lost) are not plotted.
#' @examples
#' arms <- list(
#'   Cohort1 = CorOncoEndpoints::OncoArm(pfs.median = 6, orr = 0.30, resp.cor = 0.4,
#'                                       death.prop = 0.15, os.median = 15),
#'   Cohort2 = CorOncoEndpoints::OncoArm(pfs.median = 8, orr = 0.45, resp.cor = 0.4,
#'                                       death.prop = 0.15, os.median = 18))
#' d <- SimCohorts(nsim = 20, n = c(30, 30), arms = arms, ae.rate = c(0.20, 0.35),
#'                 cutoff = 24, a.time = c(0, 12), seed = 1)
#' eps <- list(Endpoint("OS", "tte", time = "os_tte", event = "os_event"),
#'             Endpoint("PFS", "tte", time = "pfs_tte", event = "pfs_event"),
#'             Endpoint("ORR", "binary", var = "response"),
#'             Endpoint("AE", "binary", var = "ae", higher.better = FALSE))
#' crit <- data.frame(endpoint = c("ORR", "PFS", "AE"), target = c(0.3, 0.5, 0.3),
#'                    time = c(NA, 6, NA))
#' res <- SimSelection(d, eps, crit, reference = "Cohort1")
#' res
#' plot(res, "ntb", threshold = 0.1)
#' plot(res, "br")
#' @seealso \code{\link{SimSelection}}
#' @name SimSelection-methods
NULL

#' @rdname SimSelection-methods
#' @export
print.SimSelection <- function(x, n = 10, digits = 3, ...) {
  if (all(c("sim", "group", "is_reference") %in% names(x))) {
    ns <- length(unique(x$sim))
    coh <- unique(as.character(x$group))
    ref <- unique(as.character(x$group[x$is_reference %in% TRUE]))
    cat(nrow(x), " row", if (nrow(x) != 1L) "s", " of results of ", ns, " simulated trial",
        if (ns != 1L) "s", "\n", sep = "")
    cat("Cohorts: ", paste0(coh, ifelse(coh %in% ref, " (reference)", ""), collapse = ", "),
        "\n", sep = "")
    s <- attr(x, "settings")
    if (!is.null(s$scoring)) {
      cat("Scoring rule of the pairwise comparisons: ",
          if (identical(s$scoring, "peron")) "Peron" else "Gehan", "\n", sep = "")
    }
    cat("\n")
  }
  .print_df(x, digits = digits, n = n)
}
