test_that("the lines of a title are counted", {
  expect_identical(.title_lines("Win ratio"), 1L)
  expect_identical(.title_lines("Win ratio\n(threshold 1.5)"), 2L)
  expect_identical(.title_lines("a\nb\nc"), 3L)
  expect_identical(.title_lines(NULL), 1L)
  expect_identical(.title_lines(c("a", "b")), 1L)
  expect_identical(.title_lines(""), 1L)
})
