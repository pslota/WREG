% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/wregValidation.R
\name{wregValidation}
\alias{wregValidation}
\title{Validation Scheme for WREG}
\usage{
wregValidation(input, mode, compare = NULL, message = NULL,
  warnFlag = FALSE)
}
\arguments{
\item{input}{A value to validate.}

\item{mode}{Method of validation}

\item{compare}{(optional) Value to compare against if mode requires comparison}

\item{message}{(optional) Custom message for warning/error}

\item{warnFlag}{(optional) Whether or not invalid input should throw a warning/error}
}
\value{
TRUE or FALSE depending on validity of input or throws an error
}
\description{
The \code{wregValidation} function validates input in WREG-R.
}
\details{
This functions streamlines validation for the programmer so less lines of code are written
}
\examples{
invalid <- wregValidation(0, "eq", 0)

}
