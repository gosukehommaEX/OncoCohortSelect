#' Print and plot selection probabilities
#'
#' @description
#' \code{print()} shows the probability that the decision rule selects each
#' cohort, with one row per threshold and one column per cohort. \code{plot()}
#' draws these probabilities against the threshold, one line per cohort, or as
#' bars when there is a single threshold. Results of several statistics
#' combined with \code{rbind()} are printed as a data frame and cannot be
#' plotted together.
#'
#' @param x Data frame returned by \code{\link{SelectionOC}}.
#' @param digits Number of significant digits.
#' @param main Title of the plot.
#' @param ... Not used.
#' @return \code{print()} returns \code{x} invisibly. \code{plot()} returns
#'   invisibly the matrix of selection probabilities, with one row per
#'   threshold and one column per cohort.
#' @examples
#' set.seed(1)
#' res <- data.frame(sim = rep(1:200, each = 3), group = rep(c("A", "B", "C"), 200),
#'                   is_reference = rep(c(TRUE, FALSE, FALSE), 200))
#' res$ntb <- ifelse(res$is_reference, NA,
#'                   rnorm(600, rep(c(0, 0.05, 0.15), 200), 0.1))
#' oc <- SelectionOC(res, "ntb", threshold = seq(0, 0.3, by = 0.05))
#' oc
#' plot(oc)
#' @seealso \code{\link{SelectionOC}}
#' @name SelectionOC-methods
NULL

#' @rdname SelectionOC-methods
#' @export
print.SelectionOC <- function(x, digits = 3, ...) {
  stat <- unique(as.character(x$statistic))
  if (!all(c("statistic", "threshold", "group", "p_select") %in% names(x)) ||
      length(stat) != 1L) {
    return(.print_df(x, digits = digits))
  }
  cat("Probability that the rule selects each cohort\n")
  cat("Statistic: ", stat, " (", .stat_label(stat), ")\n\n", sep = "")
  M <- .oc_matrix(x)
  out <- data.frame(threshold = unique(x$threshold), M, check.names = FALSE)
  print(out, digits = digits, row.names = FALSE)
  invisible(x)
}
