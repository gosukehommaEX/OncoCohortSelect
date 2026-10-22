#' Legend of the plots (internal)
#'
#' Draws a horizontal legend below or above the plot region, or a legend at
#' one of the positions of \code{legend()} inside the plot region. The plot
#' must have a linear vertical axis.
#'
#' @param position \code{"bottom"}, \code{"top"}, a keyword of
#'   \code{legend()} or \code{"none"}.
#' @param legend Character vector of labels.
#' @param fill Colors of filled boxes, or \code{NULL} for lines.
#' @param col Colors of the lines.
#' @param lwd Width of the lines.
#' @param cex Character expansion of the labels.
#' @param line For \code{"bottom"}, the margin line of the top of the legend.
#' @return \code{NULL}, invisibly.
#' @keywords internal
#' @noRd
.oc_legend <- function(position, legend, fill = NULL, col = NULL, lwd = 2, cex = 1,
                       line = 4) {
  if (position == "none") return(invisible(NULL))
  usr <- graphics::par("usr")
  if (position %in% c("bottom", "top")) {
    # height of one margin line in user coordinates
    lu <- graphics::par("mex") * graphics::par("csi") * diff(usr[3:4]) /
      graphics::par("pin")[2]
    if (position == "bottom") {
      .hlegend(mean(usr[1:2]), usr[3] - line * lu, legend, fill = fill, col = col,
               lwd = lwd, cex = cex, yjust = 1)
    } else {
      .hlegend(mean(usr[1:2]), usr[4] + 0.3 * lu, legend, fill = fill, col = col,
               lwd = lwd, cex = cex, yjust = 0)
    }
  } else if (is.null(fill)) {
    graphics::legend(position, legend = legend, col = col, lwd = lwd, bty = "n", cex = cex)
  } else {
    graphics::legend(position, legend = legend, fill = fill, border = NA, bty = "n",
                     cex = cex)
  }
  invisible(NULL)
}
