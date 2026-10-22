test_that("the rule integrates polynomials of degree 2n - 1 exactly", {
  gl <- .gauss_legendre(5)
  expect_equal(sum(gl$w), 2, tolerance = 1e-14)
  for (k in 0:9) {
    exact <- if (k %% 2 == 1) 0 else 2 / (k + 1)
    expect_equal(sum(gl$w * gl$x ^ k), exact, tolerance = 1e-12)
  }
  expect_true(all(diff(gl$x) > 0))
  # known nodes of the 2-point rule
  expect_equal(.gauss_legendre(2)$x, c(-1, 1) / sqrt(3), tolerance = 1e-14)
})
