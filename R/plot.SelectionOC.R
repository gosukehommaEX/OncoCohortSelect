#' @rdname SelectionOC-methods
#' @export
plot.SelectionOC <- function(x, main = NULL, ...) {
  if (!all(c("statistic", "threshold", "group", "p_select") %in% names(x))) {
    stop("'x' must be the output of SelectionOC().", call. = FALSE)
  }
  if (length(unique(as.character(x$statistic))) != 1L) {
    stop("'x' contains several statistics; plot them one at a time.", call. = FALSE)
  }
  M <- .oc_matrix(x)
  thr <- unique(x$threshold)
  cols <- .oc_colors(ncol(M))
  if (is.null(main)) {
    main <- paste0("Selection by ", as.character(x$statistic[1]))
    if (length(thr) == 1L) {
      main <- paste0(main, " (threshold ", .fmt_num(thr, 4), ")")
    }
  }
  if (length(thr) == 1L) {
    graphics::barplot(M[1, ], col = cols, ylim = c(0, 1), las = 1,
                      ylab = "Probability of selection", main = main)
  } else {
    o <- order(thr)
    graphics::matplot(thr[o], M[o, , drop = FALSE], type = "l", lty = 1, lwd = 2,
                      col = cols, ylim = c(0, 1), las = 1, xlab = "Threshold",
                      ylab = "Probability of selection", main = main)
    graphics::legend("topright", legend = colnames(M), col = cols, lty = 1, lwd = 2,
                     bty = "n", cex = 0.8)
  }
  invisible(M)
}
