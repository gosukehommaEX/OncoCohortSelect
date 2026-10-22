#' Horizontal legend with spacing that follows the labels (internal)
#'
#' Draws the keys and labels of a legend on one line, centered at \code{x}.
#' Each label takes its own width, so that short labels are not followed by
#' large gaps as in a horizontal \code{legend()} with a common width.
#'
#' @param x Horizontal center, in user coordinates.
#' @param y Vertical position of the top (\code{yjust = 1}) or bottom
#'   (\code{yjust = 0}) of the legend, in user coordinates.
#' @param legend Character vector of labels.
#' @param fill Colors of filled boxes, or \code{NULL} for lines.
#' @param col Colors of the lines (when \code{fill} is \code{NULL}).
#' @param lwd Width of the lines.
#' @param cex Character expansion of the labels.
#' @param yjust \code{1} or \code{0}, see \code{y}.
#' @return Invisibly, a list with the left end of each entry (\code{start})
#'   and its width (\code{width}), in user coordinates.
#' @keywords internal
#' @noRd
.hlegend <- function(x, y, legend, fill = NULL, col = NULL, lwd = 2, cex = 1, yjust = 1) {
  op <- graphics::par(xpd = TRUE)
  on.exit(graphics::par(op))
  tw <- graphics::strwidth(legend, cex = cex)
  cw <- graphics::strwidth("M", cex = cex)
  ch <- graphics::strheight("M", cex = cex)
  key <- if (is.null(fill)) 2 * cw else cw
  gap <- 0.5 * cw
  sep <- 1.5 * cw
  width <- key + gap + tw
  total <- sum(width) + sep * (length(legend) - 1L)
  start <- x - total / 2 + c(0, cumsum(width + sep))[seq_along(legend)]
  h <- 1.5 * ch
  yc <- y + (0.5 - yjust) * h
  if (is.null(fill)) {
    graphics::segments(start, yc, start + key, yc, col = col, lwd = lwd)
  } else {
    graphics::rect(start, yc - ch / 2, start + key, yc + ch / 2, col = fill, border = NA)
  }
  graphics::text(start + key + gap, yc, legend, adj = c(0, 0.5), cex = cex)
  invisible(list(start = start, width = width))
}
