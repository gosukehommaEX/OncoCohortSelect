#' @rdname BenefitRisk-methods
#' @export
plot.BenefitRisk <- function(x, main = NULL, ...) {
  comp <- attr(x, "components")
  if (is.null(comp) || !all(c("group", "admissible", comp$label, "BR") %in% names(x))) {
    stop("'x' must be the output of BenefitRisk().", call. = FALSE)
  }
  y <- x
  class(y) <- "data.frame"
  M <- t(as.matrix(y[, c(comp$label, "BR"), drop = FALSE]))
  dimnames(M) <- list(c(comp$label, "BR"), y$group)
  K <- nrow(M)
  inadm <- y$admissible %in% FALSE
  nm <- ifelse(inadm, paste0(y$group, " *"), y$group)
  if (is.null(main)) {
    ref <- attr(x, "reference")
    main <- if (is.null(ref)) "Benefit-risk scores against target values" else
      paste0("Benefit-risk scores relative to ", ref)
  }
  op <- graphics::par(mar = c(5, 4, 3, 1) + 0.1)
  on.exit(graphics::par(op))
  bp <- graphics::barplot(M, beside = TRUE, col = c(.oc_colors(K - 1L), "grey30"),
                          ylim = c(0, 1.2), axes = FALSE, names.arg = nm,
                          ylab = "Posterior probability or score", main = main,
                          legend.text = rownames(M),
                          args.legend = list(x = "top", horiz = TRUE, bty = "n",
                                             cex = 0.8))
  graphics::axis(2, at = seq(0, 1, by = 0.2), las = 1)
  for (k in which(!is.na(comp$cutoff))) {
    graphics::segments(bp[k, ] - 0.5, comp$cutoff[k], bp[k, ] + 0.5, comp$cutoff[k],
                       lty = 2, lwd = 2)
  }
  if (any(inadm)) {
    graphics::mtext("* not admissible", side = 1, line = 3, adj = 1, cex = 0.8)
  }
  if (any(!is.na(comp$cutoff))) {
    graphics::mtext("dashed lines: admissibility cutoffs", side = 1, line = 3, adj = 0,
                    cex = 0.8)
  }
  invisible(M)
}
