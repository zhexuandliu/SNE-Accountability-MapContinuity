% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tsneMDBD.R
\name{perturbation_score_compute}
\alias{perturbation_score_compute}
\title{perturbation_score_compute}
\usage{
perturbation_score_compute(
  i,
  X,
  Y,
  Ydist_sq = NULL,
  perplexity,
  pca_result,
  length
)
}
\arguments{
\item{i}{Calculate the perturbation score for the i-th point.}

\item{X}{Original Data.}

\item{Y}{Embedding of original data.}

\item{Ydist_sq}{Distance matrix of embedding Y, can be calculated by as.matrix(dist(Y)**2).}

\item{perplexity}{Perplexity parameter to use, should be the same as when calculating the embedding Y.}

\item{pca_result}{PCA result of original data X, can be calculated by prcomp(X).}

\item{length}{Length for perturbation.}
}
\value{
Perturbation score for the i-th point in the data.
}
\description{
given the perturbation direction and length for specified point, calculate the perturbation score.
}
\examples{
perturbation_score_compute(i, X, Y, Ydist_sq, perplexity, pca_result, length)
}
