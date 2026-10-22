test_that("entries follow the widths of their labels and are centered", {
  with_null_device({
    graphics::plot.new()
    graphics::plot.window(c(0, 10), c(0, 10))
    lab <- c("won by the treatment patient", "lost", "undecided")
    r <- .hlegend(5, 5, lab, fill = c("red", "blue", "grey"))
    sep <- 1.5 * graphics::strwidth("M")
    # the gap after an entry does not depend on the longest label
    expect_equal(diff(r$start), r$width[-3] + sep, tolerance = 1e-10)
    expect_lt(r$width[2], r$width[1])
    expect_equal((r$start[1] + r$start[3] + r$width[3]) / 2, 5, tolerance = 1e-10)
    # line keys are longer than boxes
    r2 <- .hlegend(5, 5, lab, col = c("red", "blue", "grey"))
    expect_gt(r2$width[1], r$width[1])
  })
})
