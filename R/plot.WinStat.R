#' @rdname WinStat-methods
#' @export
plot.WinStat <- function(x, main = NULL, ...) {
  b <- x$by.endpoint
  if (is.null(b) || is.null(x$estimate) || is.null(x$ci)) {
    stop("'x' must be the output of WinStat().", call. = FALSE)
  }
  K <- nrow(b)
  lab <- paste0(b$priority, ". ", b$endpoint,
                ifelse(b$threshold > 0,
                       paste0(" (", .fmt_num(b$threshold, 3), ")"),
                       ""))
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
  cols <- c("#0072B2", "#D55E00", "grey75")
  left <- min(max(6, 0.55 * max(nchar(colnames(H))) + 1.5), 20)
  op <- graphics::par(mar = c(4.5, left, 5, 1))
  on.exit(graphics::par(op))
  graphics::barplot(H, horiz = TRUE, las = 1, col = cols, border = NA,
                    xlim = c(0, max(colSums(H), 0.05)), xlab = "Proportion of all pairs")
  graphics::title(main = main, line = 3, cex.main = 1)
  usr <- graphics::par("usr")
  graphics::legend(x = mean(usr[1:2]), y = usr[4], xjust = 0.5, yjust = 0,
                   legend = c("won by the treatment patient", "lost", "undecided"),
                   fill = cols, border = NA, horiz = TRUE, bty = "n", cex = 0.8,
                   xpd = TRUE)
  invisible(H)
}
