#' Print and plot benefit-risk scores
#'
#' @description
#' \code{print()} shows the definition, weight and cutoff of each component
#' and the scores of the cohorts. \code{plot()} draws, for each cohort, the
#' posterior probabilities of the components and the composite score as bars,
#' with the admissibility cutoffs as dashed lines.
#'
#' @param x Data frame returned by \code{\link{BenefitRisk}}.
#' @param digits Number of significant digits of the scores.
#' @param main Title of the plot.
#' @param ... Not used.
#' @return \code{print()} returns \code{x} invisibly. \code{plot()} returns
#'   invisibly the matrix of plotted values, with one row per component and a
#'   last row \code{BR}, and one column per cohort.
#' @examples
#' set.seed(1)
#' d <- data.frame(group = rep(c("Cohort1", "Cohort2"), each = 40),
#'                 pfs_tte = rexp(80, log(2) / rep(c(8, 6), each = 40)),
#'                 pfs_event = 1,
#'                 response = rbinom(80, 1, rep(c(0.45, 0.30), each = 40)),
#'                 ae = rbinom(80, 1, rep(c(0.35, 0.20), each = 40)))
#' eps <- list(Endpoint("PFS", "tte", time = "pfs_tte", event = "pfs_event"),
#'             Endpoint("ORR", "binary", var = "response"),
#'             Endpoint("AE", "binary", var = "ae", higher.better = FALSE))
#' crit <- data.frame(endpoint = c("ORR", "PFS", "AE"), target = c(0.3, 0.5, 0.3),
#'                    time = c(NA, 6, NA), cutoff = c(NA, NA, 0.5))
#' br <- BenefitRisk(d, eps, crit)
#' br
#' plot(br)
#' @seealso \code{\link{BenefitRisk}}
#' @name BenefitRisk-methods
NULL

#' @rdname BenefitRisk-methods
#' @export
print.BenefitRisk <- function(x, digits = 3, ...) {
  comp <- attr(x, "components")
  ref <- attr(x, "reference")
  if (!is.null(comp)) {
    if (is.null(ref)) {
      cat("Posterior benefit-risk scores against target values\n\n")
    } else {
      cat("Posterior benefit-risk scores relative to ", ref, "\n\n", sep = "")
    }
    tab <- data.frame(component = comp$label, definition = comp$definition,
                      weight = .fmt_num(comp$weight, 3),
                      cutoff = ifelse(is.na(comp$cutoff), "",
                                      .fmt_num(comp$cutoff, 3)),
                      stringsAsFactors = FALSE)
    print(tab, row.names = FALSE, right = FALSE)
    cat("\n")
  }
  .print_df(x, digits = digits)
  if (!is.null(comp) && "selected" %in% names(x)) {
    sel <- x$group[x$selected %in% TRUE]
    msg <- if (length(sel)) {
      paste(sel, collapse = ", ")
    } else if (!any(x$admissible %in% TRUE)) {
      "none (no cohort is admissible)"
    } else {
      "none of the cohorts shown"
    }
    cat("\nSelected: ", msg, "\n", sep = "")
  }
  invisible(x)
}
