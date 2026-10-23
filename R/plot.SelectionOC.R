#' @rdname SelectionOC-methods
#' @export
plot.SelectionOC <- function(x, threshold = NULL, col = NULL, main = NULL,
                             legend.position = c("bottom", "top", "topright", "topleft",
                                                 "bottomright", "bottomleft", "right",
                                                 "left", "none"),
                             cex.main = 1.2, cex.lab = 1, cex.axis = 1, cex.legend = 0.9,
                             ...) {
  if (!all(c("statistic", "threshold", "group", "p_select") %in% names(x))) {
    stop("'x' must be the output of SelectionOC().", call. = FALSE)
  }
  if (length(unique(as.character(x$statistic))) != 1L) {
    stop("'x' contains several statistics; plot them one at a time.", call. = FALSE)
  }
  legend.position <- match.arg(legend.position)
  if (!is.null(threshold) && (!is.numeric(threshold) || anyNA(threshold))) {
    stop("'threshold' must be numeric.", call. = FALSE)
  }
  .check_cex(cex.main = cex.main, cex.lab = cex.lab, cex.axis = cex.axis,
             cex.legend = cex.legend)
  M <- .oc_matrix(x)
  thr <- unique(x$threshold)
  cols <- if (is.null(col)) .oc_colors(ncol(M)) else rep_len(col, ncol(M))
  if (is.null(main)) {
    main <- .stat_label(as.character(x$statistic[1]), short = TRUE)
    if (length(thr) == 1L) {
      main <- paste0(main, " (threshold ", .fmt_num(thr, 4), ")")
    }
  }
  # names shown: the selection of no cohort is labeled in words
  shown <- colnames(M)
  shown[shown == "(none)"] <- "None admissible"
  if (length(thr) == 1L) {
    # the cohorts are named on the axis; no legend is needed
    graphics::barplot(M[1, ], names.arg = shown, col = cols, ylim = c(0, 1), las = 1,
                      ylab = "Probability of selection", main = main,
                      cex.main = cex.main, cex.lab = cex.lab, cex.axis = cex.axis,
                      cex.names = cex.axis)
    return(invisible(M))
  }
  # margin lines: axis title, legend
  base <- 2.5 + 1.2 * cex.lab
  leg_h <- 1.4 * cex.legend
  bottom <- base + if (legend.position == "bottom") leg_h + 0.6 else 0.4
  title_line <- if (legend.position == "top") 0.6 + leg_h else 1
  op <- graphics::par(mar = c(bottom, 4.5, title_line + 1.4 * cex.main, 1))
  on.exit(graphics::par(op))
  o <- order(thr)
  graphics::matplot(thr[o], M[o, , drop = FALSE], type = "l", lty = 1, lwd = 2, col = cols,
                    ylim = c(0, 1), las = 1, xlab = "Threshold",
                    ylab = "Probability of selection", cex.lab = cex.lab,
                    cex.axis = cex.axis)
  graphics::title(main = main, line = title_line, cex.main = cex.main)
  if (!is.null(threshold)) graphics::abline(v = threshold, lty = 2)
  .oc_legend(legend.position, shown, col = cols, lwd = 2, cex = cex.legend,
             line = base + 0.3)
  invisible(M)
}
