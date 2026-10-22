test_that("legends are drawn at every position", {
  with_null_device({
    graphics::plot.new()
    graphics::plot.window(c(0, 1), c(0, 1))
    for (p in c("bottom", "top", "topright", "left", "none")) {
      expect_null(.oc_legend(p, c("a", "b"), fill = c("red", "blue")))
      expect_null(.oc_legend(p, c("a", "b"), col = c("red", "blue")))
    }
  })
})
