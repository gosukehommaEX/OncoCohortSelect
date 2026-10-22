#' Print and plot win statistics
#'
#' @description
#' \code{print()} shows the cohorts compared, the proportions of pairs won,
#' lost and undecided at each priority level, and the net treatment benefit,
#' the win ratio and the win odds with their confidence intervals.
#' \code{plot()} draws one bar per priority level with the proportions of all
#' pairs won and lost at that level, and a last bar with the pairs that no
#' level decides; the title gives the net treatment benefit and the win ratio
#' with their confidence intervals.
#'
#' @param x List returned by \code{\link{WinStat}}.
#' @param digits Number of significant digits.
#' @param col Colors of the pairs won, lost and undecided (recycled).
#' @param main Title of the plot; by default the net treatment benefit and the
#'   win ratio with their confidence intervals.
#' @param legend.position Position of the legend: \code{"bottom"} (below the
#'   plot, the default) or \code{"top"} (above the plot) for a horizontal
#'   legend, a keyword of \code{\link[graphics]{legend}} such as
#'   \code{"topright"} for a legend inside the plot, or \code{"none"}.
#' @param cex.main,cex.lab,cex.axis,cex.legend Sizes of the title, of the axis
#'   titles, of the axis and bar labels, and of the legend (and notes),
#'   relative to the default size.
#' @param ... Not used.
#' @return \code{print()} returns \code{x} invisibly. \code{plot()} returns
#'   invisibly the matrix of plotted proportions (rows \code{won},
#'   \code{lost} and \code{undecided}; one column per bar, from the bottom to
#'   the top of the plot).
#' @examples
#' set.seed(1)
#' d <- data.frame(group = rep(c("Cohort1", "Cohort2"), each = 40),
#'                 os_tte = rexp(80, log(2) / rep(c(18, 15), each = 40)),
#'                 os_event = rbinom(80, 1, 0.6),
#'                 response = rbinom(80, 1, rep(c(0.45, 0.30), each = 40)))
#' eps <- list(Endpoint("OS", "tte", time = "os_tte", event = "os_event"),
#'             Endpoint("ORR", "binary", var = "response"))
#' w <- WinStat(d, eps, treatment = "Cohort1", control = "Cohort2")
#' w
#' plot(w)
#' plot(w, col = c("darkgreen", "firebrick", "grey80"), legend.position = "topright",
#'      cex.main = 0.9, cex.legend = 1)
#' @seealso \code{\link{WinStat}}
#' @name WinStat-methods
NULL

#' @rdname WinStat-methods
#' @export
print.WinStat <- function(x, digits = 3, ...) {
  s <- x$settings
  fmt <- function(v) .fmt_num(v, digits)
  if (!is.null(s)) {
    cat("Generalized pairwise comparisons: ", s$treatment, " (treatment) vs ", s$control,
        " (control)\n", sep = "")
    cat("Patients: ", x$n[["treatment"]], " and ", x$n[["control"]], " (",
        x$n[["pairs"]], " pairs); scoring rule of ",
        if (identical(s$scoring, "peron")) "Peron" else "Gehan", "\n\n", sep = "")
  }
  cat("Proportions of all pairs won, lost and still undecided by priority level:\n")
  .print_df(x$by.endpoint, digits = digits)
  e <- x$estimate
  cat("\nPairs won ", fmt(e[["p_win"]]), ", lost ", fmt(e[["p_loss"]]), ", tied ",
      fmt(e[["p_tie"]]), "\n\n", sep = "")
  if (!is.null(s)) {
    cat(round(100 * s$conf.level, 1), "% confidence intervals:\n", sep = "")
  } else {
    cat("Confidence intervals:\n")
  }
  .print_df(x$ci, digits = digits)
  invisible(x)
}
