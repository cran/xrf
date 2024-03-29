% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/xrf.R
\name{print.xrf}
\alias{print.xrf}
\title{Print an eXtreme RuleFit model}
\usage{
\method{print}{xrf}(x, ...)
}
\arguments{
\item{x}{an object of class "xrf"}

\item{...}{ignored arguments}
}
\description{
Print an eXtreme RuleFit model
}
\examples{
m <- xrf(Petal.Length ~ ., iris,
         xgb_control = list(nrounds = 2, max_depth = 2),
         family = 'gaussian')
print(m)

}
