
##--------------Estimation with Penalty by BIC----------------------##
mam_sparse_bic <- 
  function(Y,X,criteria,r1_index,r2_index,r3_index,pen,isPenColumn,lambda=lambda,A,B,C,S,
           intercept,nlam,K,degr,lam_min,eps1,maxstep1,eps2,maxstep2,gamma,dfmax,alpha){
  n <- dim(Y)[1]
  q <- dim(Y)[2]
  p <- dim(X)[2]
  
  Ybar = colMeans(Y)
  Y1 = Y - matrix(rep(Ybar,each=n),n)
  Z = bsbasefun(X,K,degr)
  Zbar = colMeans(Z)
  Z = Z - matrix(rep(Zbar,each=n),n)
  RSS = NULL
  for(r3 in r3_index){
    for(r2 in r2_index){
      for(r1 in r1_index){
        if(isPenColumn){
          fit = EstPenColumn(Y1,Z,as.matrix(A[,1:r1]),as.matrix(B[,1:r2]),as.matrix(C[,1:r3]),as.matrix(S[1:r3,1:(r1*r2)]),
                             lambda,alpha,gamma,pen,dfmax,eps1,eps2,maxstep1,maxstep2) 
          df = r1*r2*r3+fit$df*r1+K*r2+q*r3-r1^2-r2^2-r3^2
        }
        else{
          fit = EstPenSingle(Y1,Z,as.matrix(A[,1:r1]),as.matrix(B[,1:r2]),as.matrix(C[,1:r3]),as.matrix(S[1:r3,1:(r1*r2)]),
                             lambda,alpha,gamma,pen,dfmax,eps1,eps2,maxstep1,maxstep2) 
          df1 = NULL
          for(k in 1:nlam){
            activeF1 = matrix(fit$betapath[,k],nrow=q)
            df1 = c(df1,median(rowSums(activeF1)))
          }
          df = r1*r2*r3+df1*r1+K*r2+q*r3-r1^2-r2^2-r3^2
        }
        loglikelih = (n*q)*log(fit$likhd/(n*q))
        bic <- switch (criteria,
                       BIC = loglikelih + log(n*q)*df,
                       AIC = loglikelih + 2*df,
                       GCV = fit$likhd*(n*q)/(n*q-df)^2,
                       EBIC = loglikelih + log(n*q)*df + 2*(lgamma(q*p*(p+1)/2+1) 
                                                            - lgamma(df+1) - lgamma(q*p*(p+1)/2-df+1))
        )
        RSS = cbind(RSS,bic)
      }
    }
  }
  selected = which.min(RSS)
  qj = ceiling(selected/nlam)
  qj1 = selected%%nlam
  if(qj1==0) qj1=nlam
  
  lambda_opt = lambda[qj1]
  opt = assig(c(length(r1_index),length(r2_index),length(r3_index)))[,qj]
  r1_opt = r1_index[opt[1]]
  r2_opt = r2_index[opt[2]]
  r3_opt = r3_index[opt[3]]
  
  #---------------- The estimation after selection ---------------------#
  if(isPenColumn){
    fit_opt = EstPenColumn(Y1,Z,as.matrix(A[,1:r1_opt]),as.matrix(B[,1:r2_opt]),as.matrix(C[,1:r3_opt]),as.matrix(S[1:r3_opt,1:(r1_opt*r2_opt)]),
                           lambda[1:qj1],alpha, gamma, pen, dfmax, eps1, eps2, maxstep1, maxstep2) 
    activeF = activeX = fit_opt$betapath[,qj1]
  }
  else{
    fit_opt = EstPenSingle(Y1,Z,as.matrix(A[,1:r1_opt]),as.matrix(B[,1:r2_opt]),as.matrix(C[,1:r3_opt]),as.matrix(S[1:r3_opt,1:(r1_opt*r2_opt)]),
                           lambda[1:qj1],alpha, gamma, pen, dfmax, eps1, eps2, maxstep1, maxstep2) 
    activeF = matrix(fit_opt$betapath[,qj1],q,p)
    activeX = fit_opt$activeXpath[,qj1]
  }
  if(intercept)  mu = Ybar-fit_opt$Dnew%*%Zbar
  else mu = rep(0,q)
  return(list(Dnew=fit_opt$Dnew, 
              rss=fit_opt$likhd[qj1],
              df = fit_opt$df,
              mu = mu,
              activeF = activeF,
              activeX = activeX,
              lambda = lambda,
              selectedID = selected,
              lambda_opt=lambda_opt,
              RSS = RSS,
              rk_opt=c(r1_opt,r2_opt,r3_opt),
              Y = Y,
              X = X,
              Z = Z,
              degr = degr,
              K = K
              )
         )
}