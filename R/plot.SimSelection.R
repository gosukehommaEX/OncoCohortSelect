#' @rdname SimSelection-methods
#' @export
plot.SimSelection <- function(x, statistic = c("ntb", "ntb_lower", "wr", "wo", "br_diff",
                                               "br_ref", "br"),
                              threshold = NULL, col = NULL, main = NULL, ylab = NULL,
                              cex.main = 1.2, cex.lab = 1, cex.axis = 1, ...) {
  statistic <- match.arg(statistic)
  if (!all(c("group", statistic) %in% names(x))) {
    stop("'x' has no column '", statistic, "'; use the output of SimSelection().",
         call. = FALSE)
  }
  if (!is.null(threshold) && (!is.numeric(threshold) || anyNA(threshold))) {
    stop("'threshold' must be numeric.", call. = FALSE)
  }
  if (!is.null(ylab) && (!is.character(ylab) || length(ylab) != 1L || is.na(ylab))) {
    stop("'ylab' must be a single character string.", call. = FALSE)
  }
  .check_cex(cex.main = cex.main, cex.lab = cex.lab, cex.axis = cex.axis)
  v <- x[[statistic]]
  g <- as.character(x$group)
  keep <- is.finite(v)
  if (!any(keep)) stop("'x' has no finite value of '", statistic, "'.", call. = FALSE)
  vals <- split(v[keep], factor(g[keep], levels = unique(g[keep])))
  # each cohort keeps its color whatever the statistic
  coh <- unique(g)
  pal <- if (is.null(col)) .oc_colors(length(coh)) else rep_len(col, length(coh))
  cols <- pal[match(names(vals), coh)]
  ratio <- statistic %in% c("wr", "wo")
  if (is.null(main)) main <- .stat_label(statistic)
  if (is.null(ylab)) ylab <- .stat_label(statistic, short = TRUE)
  graphics::boxplot(vals, col = cols, las = 1, main = main, ylab = ylab,
                    log = if (ratio && all(v[keep] > 0)) "y" else "",
                    cex.main = cex.main, cex.lab = cex.lab, cex.axis = cex.axis)
  if (!is.null(threshold)) graphics::abline(h = threshold, lty = 2, lwd = 2)
  invisible(vals)
}
