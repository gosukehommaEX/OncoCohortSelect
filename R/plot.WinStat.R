#' @rdname WinStat-methods
#' @export
plot.WinStat <- function(x, col = c("#0072B2", "#D55E00", "grey75"), main = NULL,
                         legend.position = c("bottom", "top", "topright", "topleft",
                                             "bottomright", "bottomleft", "right", "left",
                                             "none"),
                         cex.main = 1, cex.lab = 1, cex.axis = 1, cex.legend = 0.9, ...) {
  b <- x$by.endpoint
  if (is.null(b) || is.null(x$estimate) || is.null(x$ci)) {
    stop("'x' must be the output of WinStat().", call. = FALSE)
  }
  legend.position <- match.arg(legend.position)
  .check_cex(cex.main = cex.main, cex.lab = cex.lab, cex.axis = cex.axis,
             cex.legend = cex.legend)
  cols <- rep_len(col, 3L)
  K <- nrow(b)
  lab <- paste0(b$priority, ". ", b$endpoint,
                ifelse(b$threshold > 0, paste0(" (", .fmt_num(b$threshold, 3), ")"), ""))
  H <- rbind(won = c(b$win, 0), lost = c(b$loss, 0),
             undecided = c(rep(0, K), x$estimate[["p_tie"]]))
  colnames(H) <- c(lab, "Undecided")
  # the first priority level at the top
  H <- H[, rev(seq_len(K + 1L)), drop = FALSE]
  if (is.null(main)) {
    f2 <- function(v) .fmt_num(v, 2, "f")
    part <- function(i, name) {
      r <- x$ci[i, ]
      out <- paste(name, f2(r$estimate))
      if (!is.na(r$lower) && !is.na(r$upper)) {
        lvl <- if (is.null(x$settings)) "" else
          paste0(round(100 * x$settings$conf.level, 1), "% ")
        out <- paste0(out, " (", lvl, "CI ", f2(r$lower), " to ", f2(r$upper), ")")
      }
      out
    }
    main <- paste0(part(1L, "NTB"), "; ", part(2L, "WR"))
  }
  # margin lines: axis title, legend
  base <- 2.5 + 1.2 * cex.lab
  leg_h <- 1.4 * cex.legend
  bottom <- base + if (legend.position == "bottom") leg_h + 0.6 else 0.4
  title_line <- if (legend.position == "top") 0.6 + leg_h else 1
  left <- min(max(6, 0.55 * cex.axis * max(nchar(colnames(H))) + 1.5), 20)
  op <- graphics::par(mar = c(bottom, left, title_line + 1.4 * cex.main, 1))
  on.exit(graphics::par(op))
  graphics::barplot(H, horiz = TRUE, las = 1, col = cols, border = NA,
                    xlim = c(0, max(colSums(H), 0.05)), xlab = "Proportion of all pairs",
                    cex.names = cex.axis, cex.axis = cex.axis, cex.lab = cex.lab)
  graphics::title(main = main, line = title_line, cex.main = cex.main)
  .oc_legend(legend.position, c("won by the treatment patient", "lost", "undecided"),
             fill = cols, cex = cex.legend, line = base + 0.3)
  invisible(H)
}
