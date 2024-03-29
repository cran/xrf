% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/xrf.R
\name{model.matrix.xrf}
\alias{model.matrix.xrf}
\title{Generate the design matrix from an eXtreme RuleFit model}
\usage{
\method{model.matrix}{xrf}(object, data, sparse = TRUE, ...)
}
\arguments{
\item{object}{an object of class "xrf"}

\item{data}{data to generate design matrix from}

\item{sparse}{a logical indicating whether a sparse design matrix should be used}

\item{...}{ignored arguments}
}
\description{
Generate the design matrix from an eXtreme RuleFit model
}
\examples{
m <- xrf(Petal.Length ~ ., iris,
         xgb_control = list(nrounds = 2, max_depth = 2),
         family = 'gaussian')
design <- model.matrix(m, iris, sparse = FALSE)

}
