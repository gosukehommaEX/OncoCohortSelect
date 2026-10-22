test_that("single non-empty strings are recognized", {
  expect_true(.is_string("a"))
  expect_false(.is_string(""))
  expect_false(.is_string(NA_character_))
  expect_false(.is_string(c("a", "b")))
  expect_false(.is_string(1))
  expect_false(.is_string(NULL))
})
