
##--------------Estimation with Penalty by CV----------------------##
mam_sparse_dr <- 
  function(Y,X,criteria="BIC",ncv=10,penalty="LASSO",isPenColumn=TRUE,r1_index=NULL,r2_index=NULL,
           r3_index=NULL,lambda=NULL,SABC=NULL,intercept=FALSE,initMethod=NULL,nlam=50,K=6,degr=3,lam_min=0.01,
           eps1=1e-4,maxstep1=20,eps2=1e-4,maxstep2=20,gamma=2,dfmax=NULL,alpha=1){
    n <- nrow(Y)
    q <- ncol(Y)
    p <- ncol(X)
    
    isblockwise = TRUE
    if(!is.null(initMethod)){
      Z <- bsbasefun1(X,K,degr)
      group <- rep(1:p,each=K)
      fit_mvr <- mvrblockwise(Y,Z,criteria="GCV",penalty=initMethod,isPenColumn=isblockwise,group=group)
      selectX <- fit_mvr$activeX
      X1 <- X[,which(selectX==1)]
      p <- sum(selectX)
      SABC <- NULL
    }
    else X1 = X
    
    if(degr>min(6,K-1)-1) stop("K must be larger than degree+1 !")
    if(is.null(r1_index)) r1_index = 1:min(floor(log(n)),p)
    if(is.null(r2_index)) r2_index = 1:min(K)
    if(is.null(r3_index)) r3_index = 1:min(floor(log(n)),q)
    if (penalty == "LASSO") pen <- 1
    if (penalty == "MCP")   pen <- 2 
    if (penalty=="SCAD"){    
      gamma <- 3.7
      pen <- 3
    }  
    if (gamma <= 1 & penalty=="MCP") stop("gamma must be greater than 1 for the MC penalty")
    if (gamma <= 2 & penalty=="SCAD") stop("gamma must be greater than 2 for the SCAD penalty")
    
    if (is.null(dfmax)) dfmax = p + 1
    # initial A,B,C,S
    if(is.null(SABC)){
      set.seed(1)
      r1_max = max(r1_index) 
      r2_max = max(r2_index) 
      r3_max = max(r3_index) 
      A = rbind(diag(r1_max), matrix(0,p-r1_max,r1_max))
      B = rbind(diag(r2_max), matrix(0,K-r2_max,r2_max))
      C = rbind(diag(r3_max), matrix(0,q-r3_max,r3_max))
      S = matrix(rnorm(r1_max*r2_max*r3_max),r3_max,r1_max*r2_max)
    }
    else{
      A = SABC$A
      B = SABC$B
      C = SABC$C
      S = SABC$S
    }
    if (is.null(lambda)) {
      is_setlam = 1
      if (nlam < 1||is.null(nlam)) stop("nlambda must be at least 1")
      if (n<=p) lam_min = 1e-1
      setlam = c(1,lam_min,alpha,nlam)
      Z = bsbasefun(X1,max(K),degr)
      Zbar = colMeans(Z)
      Z = Z - matrix(rep(Zbar,each=n),n)
      Ybar = colMeans(Y)
      Y1 = Y - matrix(rep(Ybar,each=n),n)
      lambda = setuplambda(Y1,Z,A,B,C,S,nlam,setlam)
    }
    else {
      is_setlam = 0
      nlam = length(lambda)
      setlam = c(1,lam_min,alpha,nlam)
    }
    #---------------- The selection by CV  ---------------------#  
    if((max(r1_index)>dim(A)[2])|(max(r2_index)>dim(B)[2])|(max(r3_index)>dim(C)[2]))
      stop("maximum number of index sequence of r1, r2, and r3 must not be larger than A, B, and C, respectively !")
    
    if(criteria=="CV") fit_dr = mam_sparse_cv(Y,X1,ncv,r1_index,r2_index,r3_index,pen,isPenColumn,lambda,A,B,C,S,
                                            intercept,nlam,K,degr,lam_min,eps1,maxstep1,eps2,maxstep2,gamma,dfmax,alpha)
    else fit_dr = mam_sparse_bic(Y,X1,criteria,r1_index,r2_index,r3_index,pen,isPenColumn,lambda,A,B,C,S,
                                 intercept,nlam,K,degr,lam_min,eps1,maxstep1,eps2,maxstep2,gamma,dfmax,alpha)

    if(!is.null(initMethod)){
      if(isPenColumn){
        id = which(selectX==1)
        idn = id[which(fit_dr$activeX==1)]
        selectX[-idn] = 0
        fit_dr$activeX = selectX
      }
      else{
        id = which(selectX==1)
        activeF= NULL
        for(j in 1:q){
          idn = id[which(fit_dr$activeF[j,]==1)]
          selectX[-idn] = 0
          activeF = rbind(activeF,selectX)
        }
        fit_dr$activeF = activeF
      }
    }
    return(fit_dr)
  }