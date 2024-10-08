########## Singularity Score ##########

#' gradient_compute
#'
#' computes gradients for t-SNE loss function
#'
#' @param Y t-SNE embedding.
#' @param P Similarity matrix in t-SNE.
#' @return Gradients for t-SNE loss function at embedding Y.
#' @examples
#' gradient_compute(Y, P)
#' @export
#' @import ggplot2
#' @import latex2exp
#' @import Rfast
#' @import viridis
#' @export
gradient_compute = function(Y, P){
  Y = c(t(Y))
  n = dim(P)[1]
  n2 = dim(P)[2]
  n_Y = length(Y)
  if ((n!=n2) | (2*n!=n_Y)){
    stop('Input dimensions do not match!')
  }

  YMatmatrix = matrix(rep(c(matrix(matrix(Y, n, 2, byrow = TRUE), 1, 2*n)), n), 2*n, n, byrow = TRUE)
  YMat = matrix(Y, 2, n)
  YnormSq = matrix(colSums(YMat ** 2), n, 1)
  YDiffDistSq = YnormSq %*% matrix(1,1,n) + matrix(1,n,1) %*% t(YnormSq) - 2 * t(YMat) %*% YMat
  YDiffDistSq_double = matrix(rep(c(matrix(YDiffDistSq)), each = 2), 2*n, n)
  P_double = matrix(rep(c(matrix(P)), each = 2), 2*n, n)
  deno = sum(1 / (1 + YDiffDistSq)) - n

  I1 = 4 * P_double * (matrix(rep(Y,n),2*n,n) - YMatmatrix) / (1 + YDiffDistSq_double)
  I2 = (-1) * 4 * (matrix(rep(Y,n),2*n,n) - YMatmatrix) / deno / ((1 + YDiffDistSq_double) ^ 2) * sum(P)

  G = rowSums(I1 + I2)

  return(G)
}

#' hessian_compute
#'
#' computes the Hessian matrix for t-SNE loss function
#'
#' @param Y t-SNE embedding.
#' @param P Similarity matrix in t-SNE.
#' @return Hessian matrix for t-SNE loss function at embedding Y.
#' @examples
#' hessian_compute(Y, P)
#' @export
#' @import ggplot2
#' @import latex2exp
#' @import Rfast
#' @import viridis
#' @export
hessian_compute = function(Y, P){
  Y = c(t(Y))
  n = dim(P)[1]
  n2 = dim(P)[2]
  n_Y = length(Y)
  if ((n!=n2) | (2*n!=n_Y)){
    stop('Input dimensions do not match!')
  }

  blockGramMatmatrix = matrix(nrow=2*n, ncol=2*n)
  blockGramMatmatrix2 = matrix(1, nrow=2*n, ncol=2*n)
  indices1 = seq(from=1, to=2*n, by=2)
  indices2 = seq(from=2, to=2*n, by=2)
  blockGramMatmatrix2[indices1, indices2] = 0
  blockGramMatmatrix2[indices2, indices1] = 0
  I2 = matrix(nrow=2*n, ncol=2*n)
  I4 = matrix(nrow=2*n, ncol=2*n)
  I5 = matrix(nrow=2*n, ncol=2*n)

  YMat = matrix(Y, 2, n)
  YnormSq = matrix(colSums(YMat ** 2), n, 1)
  YDiffDistSq = YnormSq %*% matrix(1,1,n) + matrix(1,n,1) %*% t(YnormSq) - 2 * t(YMat) %*% YMat
  deno = sum(1 / (1 + YDiffDistSq)) - n
  YMatmatrix = matrix(rep(c(matrix(matrix(Y, n, 2, byrow = TRUE), 1, 2*n)), n), 2*n, n, byrow = TRUE)
  YDiffDistSq_double = matrix(rep(c(matrix(YDiffDistSq)), each = 2), 2*n, n)

  I1 = ((-4) * P / (1 + YDiffDistSq)) %x% diag(2)
  I3 = -16 * sum(P) / deno**2 * matrix(c(rowSums((matrix(rep(Y,n),2*n,n) - YMatmatrix) / ((1 + YDiffDistSq_double) ^ 2))), 2*n, 1) %*% matrix(c(rowSums((matrix(rep(Y,n),2*n,n) - YMatmatrix) / ((1 + YDiffDistSq_double) ^ 2))), 1, 2*n)
  I4 = (4 * sum(P) / deno / ((1 + YDiffDistSq)**2)) %x% diag(2)

  for (coordinate_idx1 in c(1:2)){
    for (coordinate_idx2 in c(1:2)){
      u = YMat[coordinate_idx1,]
      v = YMat[coordinate_idx2,]
      indices1 = seq(from=coordinate_idx1, to=2*n, by=2)
      indices2 = seq(from=coordinate_idx2, to=2*n, by=2)
      tmp = matrix(u,n,1) %*% matrix(v,1,n)
      blockGramMatmatrix[indices1, indices2] = matrix(rep(diag(tmp),n),n,n) + matrix(rep(diag(tmp),each=n),n,n) - tmp - t(tmp)
      I2[indices1, indices2] = (8 * P) / ((1 + YDiffDistSq)**2) * blockGramMatmatrix[indices1, indices2]
      I5[indices1, indices2] = (-1) * (16 * sum(P)) / deno / ((1 + YDiffDistSq)**3) * blockGramMatmatrix[indices1, indices2]
    }
  }

  H = I1 + I2 + I3 + I4 + I5
  for (coordinate_idx1 in c(1:2)){
    for (coordinate_idx2 in c(1:2)){
      indices1 = seq(from=coordinate_idx1, to=2*n, by=2)
      indices2 = seq(from=coordinate_idx2, to=2*n, by=2)
      diag(H[indices1,indices2])=0
    }
  }
  tmp = apply(array(H, dim=c(2,n,2,n)), c(1,2,3), sum)
  for (i in c(1:n)){
    H[c(2*i-1, 2*i), c(2*i-1, 2*i)] = (-1) * tmp[,i,]
  }

  return (H)
}

#' singularity_score_compute
#'
#' computes the singularity score to diagnose fracture-inducing discontinuity
#'
#' @param Y t-SNE embedding.
#' @param P Similarity matrix in t-SNE.
#' @return Hessian matrix for t-SNE loss function at embedding Y.
#' @examples
#' singularity_score_compute(Y, P)
#' @export
#' @import ggplot2
#' @import latex2exp
#' @import Rfast
#' @import viridis
#' @export
singularity_score_compute = function(Y, P){
  eigen_score_pointwise = function(Hessian, ind){
    h = Hessian[c(2*ind-1, 2*ind), c(2*ind-1, 2*ind)]
    return(1/min(eigen(h)$values))
  }
  H = hessian_compute(Y, P)
  s_score = sapply(c(1:dim(Y)[1]), function(x) eigen_score_pointwise(Hessian = H, x))
  return(s_score)
}

#' plot_singularity_score
#'
#' plot singularity score
#'
#' @param Y t-SNE embedding.
#' @param s_score Singularity score.
#' @param point_size Point size in the plot.
#' @return A plot of t-SNE embedding with singularity score coloring.
#' @examples
#' plot_singularity_score(Y, s_score, point_size = 1)
#' @export
#' @import ggplot2
#' @import latex2exp
#' @import Rfast
#' @import viridis
#' @export
plot_singularity_score = function(Y, s_score, point_size = 1){
  plot_df = data.frame(x = Y[,1], y = Y[,2], s_score = s_score)
  plot_df$quantile_rank = rank(plot_df$s_score) / length(plot_df$s_score)
  p=ggplot() +
    geom_point(data = plot_df,
               aes(x = x, y = y, color = s_score),
               size = point_size) +
    scale_color_viridis(direction = 1,
                        trans = 'log10',
                        name = "Singularity\nScore") +
    xlab('tSNE1') +
    ylab('tSNE2')
  return(p)
}

#' plot_singularity_score_q
#'
#' plot singularity score
#'
#' @param Y t-SNE embedding.
#' @param s_score Singularity score.
#' @param point_size Point size in the plot.
#' @return A plot of t-SNE embedding with the quantile of singularity score as coloring.
#' @examples
#' plot_singularity_score_q(Y, s_score, point_size = 1)
#' @export
#' @import ggplot2
#' @import latex2exp
#' @import Rfast
#' @import viridis
#' @export
plot_singularity_score_q = function(Y, s_score, point_size = 1){
  plot_df = data.frame(x = Y[,1], y = Y[,2], s_score = s_score)
  plot_df$quantile_rank = rank(plot_df$s_score) / length(plot_df$s_score)
  q = c(0,0.25,0.5,0.75,1)
  p=ggplot2::ggplot() +
    geom_point(data = plot_df,
               aes(x = x, y = y, color = quantile_rank),
               size = point_size) +
    scale_color_viridis(direction = 1,
                        breaks = q,
                        labels = as.numeric(sprintf("%.5f", quantile(plot_df$s_score, q))),
                        name = "Singularity\nScore") +
    xlab('tSNE1') +
    ylab('tSNE2')
  return(p)
}

#' plot_s_score_perplexity
#'
#' plot singularity score
#'
#' @param perplexity_candidates Candidates for perplexities.
#' @param s_score_mat A matrix of singularity score for each data point at .
#' @param q Point size in the plot.
#' @return A plot of t-SNE embedding with the quantile of singularity score as coloring.
#' @examples
#' plot_s_score_perplexity(perplexity_candidates, s_score_mat, q = 0.95)
#' @export
#' @import ggplot2
#' @import latex2exp
#' @import Rfast
#' @import viridis
#' @import RtsneWithP
#' @export
plot_s_score_perplexity = function(perplexity_candidates, s_score_mat, q = 0.95){
  mean_s_score_vec = apply(s_score_mat, 2, function(s_score) {
    mean(s_score[s_score > quantile(s_score, q)], na.rm = TRUE)
  })
  p = ggplot(data = data.frame(mean = mean_s_score_vec, perplexity = perplexity_candidates)) +
  geom_point(aes(x = perplexity, y = mean))
  return(p)
}

########## Perturbation Score ##########

#' get_loss_pointwise_tsne
#'
#' get surrogate t-SNE loss for specified point
#'
#' @param yy Embedding of the point that we want to calculate loss with.
#' @param Y Embedding matrix of other points.
#' @param PMat Simalarity matrix (P matrix) of all points (with the point we want to calculate loss with as the first point).
#' @return The surrogate loss for the point yy.
#' @examples
#' get_loss_pointwise_tsne(yy, Y, Mat)
#' @export
#' @import Rfast
#' @import RtsneWithP
#' @export
get_loss_pointwise_tsne = function(yy, Y, YDistSqP1, PMat){
  n = dim(Y)[1] + 1
  yy_Y_dist_sqP1 = 1 + rowsums((Y - matrix(yy, nrow = n-1, ncol = 2, byrow = TRUE))**2)
  YDistSqP1[1,2:n] = yy_Y_dist_sqP1
  YDistSqP1[2:n,1] = yy_Y_dist_sqP1
  I1 = 2 * (PMat[1,] %*% YDistSqP1[,1])[1,1]
  I2 = log(sum(rowsums(1/YDistSqP1))-n)
  return(I1 + I2)
}

#' gradient_compute_pointwise
#'
#' computes gradients for t-SNE loss function pointwise
#'
#' @param yy Embedding of the point that we want to calculate loss with.
#' @param Y Embedding matrix of other points.
#' @param P Similarity matrix in t-SNE.
#' @return Gradients for t-SNE loss function at embedding yy.
#' @examples
#' gradient_compute_pointwise(yy, Y, P)
#' @export
#' @import ggplot2
#' @import latex2exp
#' @import Rfast
#' @import viridis
#' @export
gradient_compute_pointwise = function(yy, Y, P){
  Y = c(t(rbind(yy,Y)))
  n = dim(P)[1]
  n2 = dim(P)[2]
  n_Y = length(Y)
  if ((n!=n2) | (2*n!=n_Y)){
    stop('Input dimensions do not match!')
  }

  YMat = matrix(Y, 2, n)
  YDiffDistSq = as.matrix(Dist(t(YMat))**2)
  YDiffDistSq_double = matrix(rep(YDiffDistSq[1,], each = 2), nrow = 2)
  P_double = matrix(rep(P[1,], each = 2), nrow = 2)
  deno = sum(1 / (1 + YDiffDistSq)) - n

  yy_double = matrix(rep(yy,n),2,n)
  yy_Y_diff = yy_double - YMat
  commonterm = yy_Y_diff / (1 + YDiffDistSq_double)
  I1 = 4 * P_double * commonterm
  I2 = (-1) * 4 * commonterm / deno / (1 + YDiffDistSq_double)

  G = rowsums(I1 + I2)

  return(G)
}

# perturbation score
# draw contour plot
# run other examples

#' perturbation_score_compute
#'
#' given the perturbation direction and length for specified point, calculate the perturbation score.
#'
#' @param i Calculate the perturbation score for the i-th point.
#' @param X Original Data.
#' @param Y Embedding of original data.
#' @param Ydist_sq Distance matrix of embedding Y, can be calculated by as.matrix(dist(Y)**2).
#' @param perplexity Perplexity parameter to use, should be the same as when calculating the embedding Y.
#' @param dir_vec A list of perturbation directions.
#' @param length Length for perturbation.
#' @return Perturbation score for the i-th point in the data.
#' @examples
#' perturbation_score_compute(i, X, Y, Ydist_sq, perplexity, dir_vec, length)
#' @export
#' @import RtsneWithP
#' @export
perturbation_score_compute = function(i, X, Y, Ydist_sq = NULL, perplexity, dir_vec, length, initial_dims = 50, PCA_result = NULL, P_unnormalized = NULL, beta = NULL, approx = 0){
  n = dim(X)[1]
  p = dim(X)[2]

  if (approx == 0){
    if (is.null(Ydist_sq)){
      Ydist_sq = as.matrix(dist(Y)**2)
    }
    PScoreVec = numeric(6)
    dir_id = 1
    nsamples = n
    YDistSqP1 = Ydist_sq
    YDistSqP1[2:nsamples,2:nsamples] = as.matrix(1 + Ydist_sq[-i,-i])
    YDistSqP1[1,1] = 1
    for (direction in dir_vec) {
      X_new = rbind(X[i,] + direction * length, X[-i,])

      P_new = Rtsne(X_new,
                    initial_dims = initial_dims,
                    perplexity = perplexity,
                    theta = 0,
                    max_iter = 0,
                    Y_init = Y,
                    check_duplicates = FALSE)

      P_new = P_new$P
      Y_new_init = Y[i,]
      best_value = Inf
      best_result = NULL
      initializations_ind =
        c(i, order(P_new[1,], decreasing = TRUE)[1:2])

      for (init_ind in initializations_ind) {
        if (init_ind < i) {
          Y_new_init = Y[init_ind - 1,]
        } else{
          Y_new_init = Y[init_ind,]
        }
        OPT = optim(Y_new_init, fn = function(x){
          get_loss_pointwise_tsne(x, Y[-i,], YDistSqP1, P_new)},
          gr = function(x){gradient_compute_pointwise(x, Y[-i,], P_new)}, method = 'BFGS') # , control = list(maxit = 1000)
        if (OPT$value < best_value) {
          best_value = OPT$value
          best_result = OPT$par
        }

      }

      Y_new = best_result
      PScoreVec[dir_id] = sum((Y[i,] - Y_new) ^ 2) ^ 0.5
      dir_id = dir_id + 1
    }
    return(max(PScoreVec))
  }else if (approx == 1){
    if (is.null(Ydist_sq)){
      Ydist_sq = as.matrix(dist(Y)**2)
    }
    if (is.null(PCA_result)){
      stop('PCA result must be provided for if approx = TRUE!')
    }
    nsamples = n
    YDistSqP1 = Ydist_sq
    YDistSqP1[2:nsamples,2:nsamples] = as.matrix(1 + Ydist_sq[-i,-i])
    YDistSqP1[1,1] = 1
    PScoreVec = numeric(6)
    dir_id = 1
    for (direction in dir_vec) {
      X_new = rbind(X[i,] + direction * length, X[-i,])

      P_new = Rtsne(X_new,
                    initial_dims = initial_dims,
                    perplexity = perplexity,
                    theta = 0,
                    max_iter = 0,
                    Y_init = Y,
                    check_duplicates = FALSE,
                    pca = FALSE)

      P_new = P_new$P
      Y_new_init = Y[i,]
      best_value = Inf
      best_result = NULL
      initializations_ind = c(i, order(P_new[1,], decreasing = TRUE)[1:2])

      for (init_ind in initializations_ind) {
        if (init_ind < i) {
          Y_new_init = Y[init_ind - 1,]
        } else{
          Y_new_init = Y[init_ind,]
        }
        OPT = optim(Y_new_init, fn = function(x){
          get_loss_pointwise_tsne(x, Y[-i,], YDistSqP1, P_new)},
          gr = function(x){gradient_compute_pointwise(x, Y[-i,], P_new)}, method = 'BFGS', control = list(maxit = 100))
        if (OPT$value < best_value) {
          best_value = OPT$value
          best_result = OPT$par
        }

      }

      Y_new = best_result
      PScoreVec[dir_id] = sum((Y[i,] - Y_new) ^ 2) ^ 0.5
      dir_id = dir_id + 1
    }
    return(max(PScoreVec))
  }else{
    if (is.null(Ydist_sq)){
      Ydist_sq = as.matrix(dist(Y)**2)
    }
    if (is.null(PCA_result)){
      stop('PCA result must be provided for if approx = 2!')
    }
    if (is.null(P_unnormalized)){
      stop('Unnormalized P must be provided for if approx = 2!')
    }
    if (is.null(beta)){
      stop('Beta must be provided for if approx = 2!')
    }
    beta = beta[-i]
    P_un = P_unnormalized
    P_unnormalized[2:n,2:n] = P_un[-i,-i]
    nsamples = dim(Y)[1]
    YDistSqP1 = Ydist_sq
    YDistSqP1[2:nsamples,2:nsamples] = as.matrix(1 + Ydist_sq[-i,-i])
    YDistSqP1[1,1] = 1
    PScoreVec = numeric(6)
    dir_id = 1
    for (direction in dir_vec) {
      X_new = rbind(X[i,] + direction * length, X[-i,])

      P_new = approxP(X[i,] + direction * length, X[-i,], beta, P_unnormalized, perplexity)

      Y_new_init = Y[i,]
      best_value = Inf
      best_result = NULL
      initializations_ind = c(i, order(P_new[1,], decreasing = TRUE)[1:2])

      for (init_ind in initializations_ind) {
        if (init_ind < i) {
          Y_new_init = Y[init_ind - 1,]
        } else{
          Y_new_init = Y[init_ind,]
        }
        OPT = optim(Y_new_init, fn = function(x){
          get_loss_pointwise_tsne(x, Y[-i,], YDistSqP1, P_new)},
          gr = function(x){gradient_compute_pointwise(x, Y[-i,], P_new)}, method = 'BFGS', control = list(maxit = 100))
        if (OPT$value < best_value) {
          best_value = OPT$value
          best_result = OPT$par
        }
        # OPT = nloptr(Y_new_init, eval_f = function(x){
        #   get_loss_pointwise_tsne(x, Y[-i,], P_new)},
        #   eval_grad_f = function(x){gradient_compute_pointwise(x, Y[-i,], P_new)}, opts = list(maxeval = 5, maxtime = 1))
        # if (OPT$objective < best_value) {
        #   best_value = OPT$objective
        #   best_result = OPT$solution
        # }

      }

      Y_new = best_result
      PScoreVec[dir_id] = sum((Y[i,] - Y_new) ^ 2) ^ 0.5
      dir_id = dir_id + 1
    }
    return(max(PScoreVec))
  }
}

#####################################################################
#' get_P_tsne
#'
#' R function to calculate P matrix of t-SNE (https://github.com/jdonaldson/rtsne)
#'
#' @param X Pre-processed X maatrix
#' @param perplexity Perplexity of t-SNE algorithm.
#' @return P matrix, unnormalized P matrix, and beta (1/2sigma^2).
#' @examples
#' get_P_tsne(X, perplexity)
#' @export
#' @import Rfast
#' @export
get_P_tsne = function(X, perplexity) {
  .Hbeta = function(D, beta) {
    P = exp(-D * beta)
    sumP = sum(P)
    if (sumP == 0) {
      H = 0
      P = D * 0
    } else {
      H = log(sumP) + beta * sum(D %*% P) / sumP
      P = P / sumP
    }
    r = {
    }
    r$H = H
    r$P = P
    r
  }
  .Hbeta_unnormalized = function(D, beta) {
    P = exp(-D * beta)
    sumP = sum(P)
    if (sumP == 0) {
      H = 0
      P = D * 0
    } else {
      H = log(sumP) + beta * sum(D %*% P) / sumP
    }
    r = {
    }
    r$H = H
    r$P = P
    r
  }
  .x2p = function(X,
                  perplexity = 15,
                  tol = 1e-5) {
    if ('dist' %in% class(X)) {
      D = X
      n = attr(D, 'Size')
    } else{
      D = Dist(X) ** 2
      n = dim(X)[1]
    }

    D = as.matrix(D)
    P = matrix(0, n, n)
    P_unnormalized = matrix(0, n, n)
    beta = rep(1, n)
    logU = log(perplexity)

    for (i in 1:n) {
      betamin = -Inf
      betamax = Inf
      Di = D[i,-i]
      hbeta = .Hbeta(Di, beta[i])
      H = hbeta$H

      thisP = hbeta$P
      Hdiff = H - logU

      tries = 0


      while (abs(Hdiff) > tol && tries < 200) {
        if (Hdiff > 0) {
          betamin = beta[i]
          if (is.infinite(betamax))
            beta[i] = beta[i] * 2
          else
            beta[i] = (beta[i] + betamax) / 2
        } else{
          betamax = beta[i]
          if (is.infinite(betamin))
            beta[i] = beta[i] / 2
          else
            beta[i] = (beta[i] + betamin) / 2
        }

        hbeta = .Hbeta(Di, beta[i])
        H = hbeta$H
        thisP = hbeta$P
        Hdiff = H - logU
        tries = tries + 1
      }
      hbeta_unnormalized = .Hbeta_unnormalized(Di, beta[i])
      thisP_unnormalized = hbeta_unnormalized$P
      P[i, -i]  = thisP
      P_unnormalized[i, -i] = thisP_unnormalized
    }

    r = {
    }
    r$P = P
    r$P_unnormalized = P_unnormalized
    r$beta = beta
    sigma = sqrt(1 / beta)
    r
  }
  eps = 0#2^(-52)
  out = .x2p(X, perplexity, 1e-05)
  P = out$P
  beta = out$beta
  P = 0.5 * (P + t(P))
  P[P < eps] <- eps
  P = P / sum(P)
  return(list(P = P, P_unnormalized = out$P_unnormalized, beta = beta))
}

#' approxP
#'
#' R function to calculate approximated P matrix of t-SNE
#'
#' @param x_new The new x.
#' @param X The rest of X matrix.
#' @param beta beta for corresponding X.
#' @param P_unnormalized The unnormalized P matrix rearranged to put x_new as the first one.
#' @return approximated P matrix when changing x_new.
#' @examples
#' approxP(x_new, X, beta, P_unnormalized, perplexity)
#' @export
#' @import Rfast
#' @export
approxP = function(x_new, X, beta, P_unnormalized, perplexity){
  .Hbeta = function(D, beta) {
    P = exp(-D * beta)
    sumP = sum(P)
    if (sumP == 0) {
      H = 0
      P = D * 0
    } else {
      H = log(sumP) + beta * sum(D %*% P) / sumP
      P = P / sumP
    }
    r = {
    }
    r$H = H
    r$P = P
    r
  }
  .Hbeta_unnormalized = function(D, beta) {
    P = exp(-D * beta)
    sumP = sum(P)
    if (sumP == 0) {
      H = 0
      P = D * 0
    } else {
      H = log(sumP) + beta * sum(D %*% P) / sumP
    }
    r = {
    }
    r$H = H
    r$P = P
    r
  }


  X = normalize_input(rbind(x_new,X))
  n = dim(X)[1]
  p = dim(X)[2]
  Xdistsq = rowsums((X[-1,] - matrix(c(X[1,]), nrow = n-1, ncol = p, byrow = TRUE))**2)
  P_unnormalized[2:n,1] = exp(-Xdistsq * beta)

  logU = log(perplexity)
  betamin = -Inf
  betamax = Inf
  Di = Xdistsq
  beta1 = 1
  tol = 1e-5
  hbeta = .Hbeta(Di, beta1)
  H = hbeta$H

  thisP = hbeta$P
  Hdiff = H - logU

  tries = 0

  while (abs(Hdiff) > tol && tries < 200) {
    if (Hdiff > 0) {
      betamin = beta1
      if (is.infinite(betamax))
        beta1 = beta1 * 2
      else
        beta1 = (beta1 + betamax) / 2
    } else{
      betamax = beta1
      if (is.infinite(betamin))
        beta1 = beta1 / 2
      else
        beta1 = (beta1 + betamin) / 2
    }

    hbeta = .Hbeta(Di, beta1)
    H = hbeta$H
    thisP = hbeta$P
    Hdiff = H - logU
    tries = tries + 1
  }
  hbeta_unnormalized = .Hbeta_unnormalized(Di, beta1)
  thisP_unnormalized = hbeta_unnormalized$P
  P_unnormalized[1,2:n] = thisP_unnormalized
  P_new = P_unnormalized/rowsums(P_unnormalized)
  P_new = 0.5 * (P_new + t(P_new))
  P_new = P_new / sum(colsums(P_new))
  return(P_new)
}
