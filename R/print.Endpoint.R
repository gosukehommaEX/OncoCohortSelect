#' @rdname Endpoint
#' @param x An \code{Endpoint} object.
#' @param ... Not used.
#' @export
print.Endpoint <- function(x, ...) {
  if (x$type == "binary") {
    cat("<Endpoint> ", x$name, ": binary\n", sep = "")
    pos <- if (is.null(x$positive)) "" else
      paste0(" (", paste(x$positive, collapse = ", "), " count as 1)")
    cat("  values: ", x$var, pos, "\n", sep = "")
    cat("  favorable: ", if (x$higher.better) "a value of 1" else "a value of 0", "\n",
        sep = "")
  } else {
    cat("<Endpoint> ", x$name, ": time to event\n", sep = "")
    ind <- if (is.null(x$censor)) paste0("event: ", x$event, " (1 = event)") else
      paste0("censor: ", x$censor, " (0 = event)")
    cat("  time: ", x$time, ", ", ind, "\n", sep = "")
    cat("  favorable: ", if (x$higher.better) "longer times" else "shorter times", "\n",
        sep = "")
  }
  invisible(x)
}
