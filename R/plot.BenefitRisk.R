#' @rdname BenefitRisk-methods
#' @export
plot.BenefitRisk <- function(x, col = NULL, main = NULL,
                             legend.position = c("bottom", "top", "topright", "topleft",
                                                 "bottomright", "bottomleft", "right",
                                                 "left", "none"),
                             cex.main = 1.2, cex.lab = 1, cex.axis = 1, cex.legend = 0.9,
                             ...) {
  comp <- attr(x, "components")
  if (is.null(comp) || !all(c("group", "admissible", comp$label, "BR") %in% names(x))) {
    stop("'x' must be the output of BenefitRisk().", call. = FALSE)
  }
  legend.position <- match.arg(legend.position)
  .check_cex(cex.main = cex.main, cex.lab = cex.lab, cex.axis = cex.axis,
             cex.legend = cex.legend)
  y <- x
  class(y) <- "data.frame"
  M <- t(as.matrix(y[, c(comp$label, "BR"), drop = FALSE]))
  dimnames(M) <- list(c(comp$label, "BR"), y$group)
  K <- nrow(M)
  cols <- if (is.null(col)) c(.oc_colors(K - 1L), "grey30") else rep_len(col, K)
  inadm <- y$admissible %in% FALSE
  nm <- ifelse(inadm, paste0(y$group, " *"), y$group)
  if (is.null(main)) {
    ref <- attr(x, "reference")
    main <- if (is.null(ref)) "Benefit-risk scores against target values" else
      paste0("Benefit-risk scores relative to ", ref)
  }
  notes <- c(if (any(!is.na(comp$cutoff))) "dashed lines: admissibility cutoffs",
             if (any(inadm)) "* not admissible")
  # margin lines: group names, notes, legend
  note_line <- 1.3 + 1.2 * cex.axis
  base <- if (length(notes)) note_line + 1.2 * cex.legend else note_line
  leg_h <- 1.4 * cex.legend
  bottom <- base + if (legend.position == "bottom") leg_h + 0.6 else 0.4
  title_line <- if (legend.position == "top") 0.6 + leg_h else 1
  op <- graphics::par(mar = c(bottom, 4.5, title_line + 1.4 * cex.main, 1))
  on.exit(graphics::par(op))
  bp <- graphics::barplot(M, beside = TRUE, col = cols, ylim = c(0, 1), axes = FALSE,
                          names.arg = nm, cex.names = cex.axis, cex.lab = cex.lab,
                          ylab = "Posterior probability or score")
  graphics::axis(2, at = seq(0, 1, by = 0.2), las = 1, cex.axis = cex.axis)
  graphics::title(main = main, line = title_line, cex.main = cex.main)
  for (k in which(!is.na(comp$cutoff))) {
    graphics::segments(bp[k, ] - 0.5, comp$cutoff[k], bp[k, ] + 0.5, comp$cutoff[k],
                       lty = 2, lwd = 2)
  }
  if (length(notes)) {
    graphics::mtext(paste(notes, collapse = "; "), side = 1, line = note_line,
                    cex = cex.legend)
  }
  .oc_legend(legend.position, rownames(M), fill = cols, cex = cex.legend, line = base + 0.3)
  invisible(M)
}
