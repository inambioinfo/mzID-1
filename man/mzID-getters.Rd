% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/generics.R
\name{mzID-getters}
\alias{evidence}
\alias{files}
\alias{id}
\alias{idScanMap}
\alias{mzID-getters}
\alias{parameters}
\alias{software}
\title{Getter functions for identification data}
\usage{
evidence(object, safeNames = TRUE)

id(object, safeNames = TRUE)

idScanMap(object)

parameters(object)

software(object)

files(object)
}
\arguments{
\item{object}{An mzID or mzIDCollection object}

\item{safeNames}{Logical. Should column names be lowered to ensure 
compitability between different versions of the mzIdentML schema. Defaults to
TRUE}
}
\value{
A data frame or a list of data frames in the case of mzIDCollections
}
\description{
This set of functions are used to extract data from mzID and mzIDCollection
objects.
}
\seealso{
\code{\link{mzID-class}} \code{\link{mzIDCollection-class}}
}

