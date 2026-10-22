test_that("the bars are the proportions won and lost at each level", {
  d <- fixture("gpc_cont.csv")
  w <- WinStat(d, fixture_endpoints(), treatment = "T", control = "C", group = "arm",
               priority = c("os", "resp", "os", "ae"), threshold = c(2, 0, 0, 0))
  H <- with_null_device(plot(w))
  expect_identical(colnames(H), c("Undecided", "4. ae", "3. os", "2. resp", "1. os (2)"))
  expect_identical(rownames(H), c("won", "lost", "undecided"))
  expect_equal(unname(H["won", 5:2]), w$by.endpoint$win)
  expect_equal(unname(H["lost", 5:2]), w$by.endpoint$loss)
  expect_equal(unname(H["undecided", 1]), w$estimate[["p_tie"]])
  expect_equal(sum(H), 1, tolerance = 1e-12)
  expect_error(plot(structure(list(), class = "WinStat")), "WinStat")
})

test_that("colors, sizes and the legend can be chosen and par() is restored", {
  d <- fixture("gpc_cont.csv")
  w <- WinStat(d, fixture_endpoints(), treatment = "T", control = "C", group = "arm")
  H <- with_null_device(plot(w))
  for (p in c("bottom", "top", "topright", "none")) {
    H2 <- with_null_device({
      m0 <- graphics::par("mar")
      out <- plot(w, col = "black", legend.position = p, cex.main = 0.8, cex.lab = 1.3,
                  cex.axis = 1.2, cex.legend = 1.1)
      expect_identical(graphics::par("mar"), m0)
      out
    })
    expect_identical(H2, H)
  }
  expect_error(with_null_device(plot(w, legend.position = "middle")))
  expect_error(plot(w, cex.main = 0), "cex.main")
})
