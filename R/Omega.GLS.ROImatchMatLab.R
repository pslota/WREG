

#' Weighing Matrix for ROI-GLS/skew (WREG)
#'
#'@description
#'\code{Omega.GLS.ROImatchMatLab} calculates the weighting function for a 
#'generalized least-squares regression using regions-of-influence.  This is largely
#'legacy code to match WREG v. 1.05 idiosyncrasies.
#'
#' @param alpha A number, required only for \dQuote{GLS} and \dQuote{GLSskew}.  
#' \code{alpha} is a parameter used in the estimated cross-correlation between site
#' records.  See equation 20 in the WREG v. 1.05 manual.  The arbitrary, default value 
#' is 0.01.  The user should fit a different value as needed.
#' @param theta A number, required only for \dQuote{GLS} and \dQuote{GLSskew}.  
#' \code{theta} is a parameter used in the estimated cross-correlation between site
#' records.  See equation 20 in the WREG v. 1.05 manual.  The arbitrary, default value 
#' is 0.98.  The user should fit a different value as needed.
#' @param Independent A dataframe containing three variables: \code{StationID} is the 
#' numerical identifier (without a leading zero) of each site, \code{Lat} is the latitude
#' of the site, in decimal degrees, and \code{Long} is the longitude of the site, in decimal
#' degrees.  The sites must be presented in the same order as \code{Y}.  Required only for
#' \dQuote{GLS} and \dQuote{GLSskew}.  This includes only sites in the current region 
#' of influence.
#' @param X The independent variables in the regression, with any transformations 
#' already applied.  Each row represents a site and each column represents
#' a particular independe variable.  (If a leading constant is used, it should be 
#' included here as a leading column of ones.)  The rows must be in the same order as
#' the dependent variables in \code{Y}.  This includes only sites in the current region 
#' of influence.
#' @param Y The dependent variable of interest, with any transformations already 
#' applied.  This includes only sites in the current region of influence.
#' @param RecordLengths This input is required for \dQuote{WLS}, \dQuote{GLS} and 
#' \dQuote{GLSskew}.  For \dQuote{GLS} and \dQuote{GLSskew}, \code{RecordLengths} 
#' should be a matrix whose rows and columns are in the same order as \code{Y}.  Each 
#' \code{(r,c)} element represents the length of concurrent record between sites 
#' \code{r} and \code{c}.  The diagonal elements therefore represent each site's full
#' record length.  For \dQuote{WLS}, the only the at-site record lengths are needed.
#' In the case of \dQuote{WLS}, \code{RecordLengths} can be a vector or the matrix 
#' described for \dQuote{GLS} and \dQuote{GLSskew}.  This includes only sites in the 
#' current region of influence.
#' @param LP3 A dataframe containing the fitted Log-Pearson Type III standard
#' deviate, standard deviation and skew for each site.  The names of this data frame are
#' \code{S}, \code{K} and \code{G}.  For \dQuote{GLSskew}, the regional skew value must 
#' also be provided in a variable called \code{GR}.  The order of the rows must be the same
#' as \code{Y}.  This includes only sites in the current region of influence.
#' @param MSEGR A number. The mean squared error of the regional skew.  Required only for
#' \dQuote{GLSskew}.
#' @param TY A number.  The return period of the event being modeled.  Required only for 
#' \dQuote{GLSskew}.  The default value is \code{2}.  (See the \code{Legacy} details below.)
#' @param Peak A logical.  Indicates if the event being modeled is a peak flow event
#' or a low-flow event.  \code{TRUE} indicates a peak flow, while \code{FALSE} indicates
#' a low-flow event.
#' @param X.all The independent variables for all sites in the network, with any 
#' transformations already applied.  Each row represents a site and each column 
#' represents a particular independe variable.  (If a leading constant is used, it 
#' should be included here as a leading column of ones.)
#' @param LP3.all A dataframe containing the fitted Log-Pearson Type III standard
#' deviate, standard deviation and skew for all sites in the network.  The names of 
#' this data frame are \code{S}, \code{K} and \code{G}.  For \dQuote{GLSskew}, the 
#' regional skew value must also be provided in a variable called \code{GR}.  The 
#' order of the rows must be the same as \code{Y}.
#' @param DistMeth Required for \dQuote{GLS} and \dQuote{GLSskew}.  A value of \code{1} 
#' indicates that the "Nautical Mile" approximation should be used to calculate inter-site
#' distances.  A value of \code{2} designates the Haversine approximation.  See 
#' \code{\link{Dist.WREG}}.  The default value is \code{2}.  (See the \code{Legacy} 
#' details below.)
#'
#'@details This is a legacy function that matches the idiosyncrasies of WREG v. 1.05.
#'This includes using all sites to implement the sigma regression.
#'
#'See \code{\link{Omega.GLS}} for more information on the \dQuote{GLS} 
#'weighting estimates.
#'
#'This function will become obsolete once all idiosyncrasies are assessed.
#'
#'@return \code{Omega.GLS.ROImatchMatLab} returns a list with two elements:
#'\item{GSQ}{The estimated model error variance.}
#'\item{Omega}{The estimated weighting matrix.}
#'@import stats
#'@export
Omega.GLS.ROImatchMatLab <- function(alpha=0.01,theta=0.98,Independent,X,Y,RecordLengths,
  LP3,MSEGR=NA,TY=2,Peak=T,X.all,LP3.all,DistMeth=2) {
  # William Farmer, January 27, 2015
  #
  # WREG v 1.05 (MatLab) is inconsistent in which components are used to develop equations in RoI-WLS
  # Eq. 15 is implemented with all sites
  
  ## Determining if skew adjustment is requested
  SkewAdj<-F # default: no skew adjustment
  if (!is.na(MSEGR)) {
    SkewAdj<-T # If user provides a mean squared-error of regional skew, then use skew adjustment.
  }
  
  ## Create distance matrix and concurrent record lengths
  ##    (For skew-adjusted GLS: Also calculates the LP3 partial derivatives, mean squared-errors of at-site skew and the variance of at-site skew.)
  Dists <- matrix(NA,ncol=length(Y),nrow=length(Y)) # Empty matrix for intersite distances
  M <- RecordLengths # Just renaming input for ease.  (Should probably correct later...)
  if (SkewAdj) { # Make empty vectors for GLS-skew
    dKdG <- vector(length=length(Y)) # Empty vector for LP3 partial derivatives
    MSEg <- vector(length=length(Y)) # Empty vector for mean squared-error of at-site skew
    Varg <- vector(length=length(Y)) # Empty vector for variance of at-site skew
    ### Convert return period into probability
    if (Peak) { # if a peak flow is being estimated
      Zp <- -stats::qnorm(1/TY) 
    } else { # if a low flow is being estimated
      Zp <- stats::qnorm(1/TY)
    }
  }
  for (i in 1:length(Y)) {
    for (j in 1:length(Y)) {
      if (i!=j) {
        ### Calculate intersite distance via subroutine.
        ###     DistMeth==1 applies the 'Nautical Mile' approximation from WREG v 1.05
        ###     DistMeth==2 applies Haversine approximation
        Dists[i,j] <- Dist.WREG(Lat1=Independent$Lat[i],Long1=Independent$Long[i],Lat2=Independent$Lat[j],Long2=Independent$Long[j],method=DistMeth) # Intersite distance, miles
      }
    }
    if (SkewAdj) { # Additional calculations for skew-adjusted GLS
      ### LP3 Partial Derivative
      dKdG[i] <- (Zp^2-1)/6+LP3$G[i]*(Zp^3-6*Zp)/54-LP3$G[i]^2*(Zp^2-1)/72+Zp*LP3$G[i]^3/324+5*LP3$G[i]^4/23328 # LP3 partial derivative. Eq 23.
      ### Variance of at-site skew
      a <- -17.75/M[i,i]^2+50.06/M[i,i]^3 # Coefficeint for calculation of the variance of at-site skew.  Eq 27.
      b1 <- 3.92/M[i,i]^0.3-31.1/M[i,i]^0.6+34.86/M[i,i]^0.9  # Coefficeint for calculation of the variance of at-site skew.  Eq 28.
      c1 <- -7.31/M[i,i]^0.59+45.9/M[i,i]^1.18-86.5/M[i,i]^1.77  # Coefficeint for calculation of the variance of at-site skew.  Eq 29.
      Varg[i] <- (6/M[i,i]+a)*(1+LP3$GR[i]^2*(9/6+b1)+LP3$GR[i]^4*(15/48+c1)) # Variance of at-site skew. Eq 26.
      ### Mean squared-error of at-site skew
      ###   These equations are not included or described in v1.05 manual.  They are similar to Eq 28 and 29.
      ###   These equations, which appear in the v1.05 code, are documented in Griffis and Stedinger (2009); Eq 3, 4, 5 and 6.
      b <- 3.93/M[i,i]^0.3-30.97/M[i,i]^0.6+37.1/M[i,i]^0.9 # Coefficient for the calculation of mean squared-error of at-site skew.
      c <- -6.16/M[i,i]^0.56+36.83/M[i,i]^1.12-66.9/M[i,i]^1.68 # Coefficient for the calculation of mean squared-error of at-site skew.
      MSEg[i] <- (6/M[i,i]+a)*(1+LP3$G[i]^2*(9/6+b)+LP3$G[i]^4*(15/48+c)) # Mean squared-error of at-site skew.
    }
  }
  Rhos <- theta^(Dists/(alpha*Dists+1)) # Estimated intersite correlation. Eq 20.
  
  if (SkewAdj) { # if skew-adjusted GLS
    ### Calculate skew weights.
    Wg <- MSEGR/(MSEg+MSEGR) # skew weight. Eq 17.
    ### Calculate covariances between at-site skews
    Covgg <- matrix(NA,ncol=length(Y),nrow=length(Y)) # Empty matrix for covariances between at-site skews.
    for (i in 1:length(Y)) {
      for (j in 1:length(Y)) {
        if (i!=j) {
          Covgg[i,j] <- M[i,j]*sign(Rhos[i,j])*abs(Rhos[i,j])^3*sqrt(Varg[i]*Varg[j])/sqrt((M[i,j]+M[i,i])*(M[i,j]+M[j,j])) # Covariance between at-site skews. Eq 24 and 25
        }
      }
    }
  }
  
  ## Baseline OLS sigma regression. Eq 15.
  Omega <- diag(nrow(X.all)) # OLS weighting matrix (identity)
  B.SigReg <- solve(t(X.all)%*%solve(Omega)%*%X.all)%*%t(X.all)%*%solve(Omega)%*%LP3.all$S # OLS estimated coefficients for k-variable model of LP3 standard deviation.
  # BUG: MatLab fits beta regression (Eq 15) using all sites.  See lines 1305-1316 and 1372-1378 of WREG v 1.05
  Yhat.SigReg <- X%*%B.SigReg # Estimates from sigma regression
  
  ## NOTE: This iteration procedure is currently implemented in WREG v1.05, though not described in the manual.
  ##        It searches across 30 possible values of model-error variance, looks for a sign-change, and then repeats thirty searches on the identified interval.
  ##        It may be possible to improve performance by stopping th loop after a sign change rather than searching the entire space.
  
  ## Set variables to control iterative procedure
  Target<-length(Y) - ncol(X) # Target value of iterations. RHS of Eq 21.
  GInt <- 30 # Number of intervals to consider (doubled below)
  Gstep <- 2*var(Y)/(GInt-1) # Length of step
  ## Coarse intervals.
  Omega <- diag(nrow(X)) # OLS weighting matrix (identity), just to initialize size
  Iterations <- matrix(0,ncol=2,nrow=GInt) # Empty dataframe to store results
  Iterations <- data.frame(Iterations); names(Iterations) <- c('GSQ','Deviation') # Formatting empty dataframe.  Will contain estimated model-error variance (GSQ) and deviation from target.
  for (w in 1:GInt) {
    GSQ <- (w-1)*Gstep; Iterations$GSQ[w]<-GSQ; # guess at model error variance
    for (i in 1:length(Y)) {
      for (j in 1:length(Y)) {
        if (i==j) { # Diagonal elements of weighting matrix
          if (SkewAdj) { # if skew-adjusted GLS, use Eq 22 (correct manual to match Giffis and Stedinger (2007) Eq 5; WREG v1.05 code is correct)
            Omega[i,j] <-  GSQ + 
              Yhat.SigReg[i]^2*(1+LP3$K[i]*LP3$G[i]+
                  0.5*LP3$K[i]^2*(1+0.75*LP3$G[i]^2)+
                  Wg[i]*LP3$K[i]*dKdG[i]*(3*LP3$G[i]+0.75*LP3$G[i]^3)+
                  Wg[i]^2*dKdG[i]^2*(6+9*LP3$G[i]^2+1.875*LP3$G[i]^4))/M[i,j] + 
              (1-Wg[i])^2*Yhat.SigReg[i]^2*MSEGR*dKdG[i]^2
          } else { # if normal GLS, use Eq 19.
            Omega[i,j] <-  GSQ + Yhat.SigReg[i]^2*
              (1+LP3$K[i]*LP3$G[i]+0.5*LP3$K[i]^2*
                  (1+0.75*LP3$G[i]^2))/M[i,j]
          }
        } else { # Off-diagonal elements of weighting matrix
          if (SkewAdj) { # if skew-adjusted GLS, use Eq 22 (correct manual to match Giffis and Stedinger (2007) Eq 5; WREG v1.05 code is correct)
            Omega[i,j] <- Rhos[i,j]*Yhat.SigReg[i]*Yhat.SigReg[j]*M[i,j]*
              (1+0.5*LP3$K[i]*LP3$G[i]+0.5*LP3$K[j]*LP3$G[j]+
                  0.5*LP3$K[i]*LP3$K[j]*(Rhos[i,j]+0.75*LP3$G[i]*LP3$G[j])+
                  0.5*Wg[j]*LP3$K[i]*LP3$G[j]*dKdG[j]*(3*Rhos[i,j]+0.75*LP3$G[i]*LP3$G[j])+
                  0.5*Wg[i]*LP3$K[j]*LP3$G[i]*dKdG[i]*(3*Rhos[i,j]+0.75*LP3$G[i]*LP3$G[j])+
                  Wg[i]*Wg[j]*Yhat.SigReg[i]*Yhat.SigReg[j]*dKdG[i]*dKdG[j]*Covgg[i,j])/M[i,i]/M[j,j]
          } else { # if normal GLS, use Eq 19.
            Omega[i,j] <- Rhos[i,j]*Yhat.SigReg[i]*Yhat.SigReg[j]*M[i,j]*
              (1+0.5*LP3$K[i]*LP3$G[i]+0.5*LP3$K[j]*LP3$G[j]+
                  0.5*LP3$K[i]*LP3$K[j]*(Rhos[i,j]+0.75*LP3$G[i]*LP3$G[j]))/M[i,i]/M[j,j]
          }
        }
      }
    }
    B_hat <- solve(t(X)%*%solve(Omega)%*%X)%*%t(X)%*%solve(Omega)%*%Y # Use weighting matrix to estimate regression coefficients
    Iterations$Deviation[w] <- t(Y-X%*%B_hat)%*%solve(Omega)%*%(Y-X%*%B_hat)-Target # Difference between result and target value. Eq 21.
  }
  ## Finer intervals.  Expands iterval with sign change to get closer to zero.
  Signs <- sign(Iterations$Deviation); LastPos <- which(diff(Signs)!=0) # Finds where sign changes from positive to negative
  if (length(LastPos)==0) { # If no change in sign of deviation
    BestPos <- which(abs(Iterations$Deviation)==min(abs(Iterations$Deviation))) # Use the minimum deviation
    GSQ <- Iterations$GSQ[BestPos] # Best estiamte of model-error variance
  } else { # There is a sign change, so expand the interval with sign change.
    Iterations2 <- matrix(0,ncol=2,nrow=GInt) # Empty matrix to store finer intervals.
    Iterations2 <- data.frame(Iterations); names(Iterations) <- c('GSQ','Deviation') # Formatting empty matrix
    Gstep <- (Iterations$GSQ[LastPos+1]-Iterations$GSQ[LastPos])/(GInt-1) # Step for finer intervals
    for (w in 1:GInt) {
      GSQ <- Iterations$GSQ[LastPos]+(w-1)*Gstep; Iterations2$GSQ[w]<-GSQ; # estimate of model-error variance
      for (i in 1:length(Y)) {
        for (j in 1:length(Y)) {
          if (i==j) { # Diagonal elements of weighting matrix
            if (SkewAdj) { # if skew-adjusted GLS, use Eq 22 (correct manual to match Giffis and Stedinger (2007) Eq 5; WREG v1.05 code is correct)
              Omega[i,j] <-  GSQ + 
                Yhat.SigReg[i]^2*(1+LP3$K[i]*LP3$G[i]+
                    0.5*LP3$K[i]^2*(1+0.75*LP3$G[i]^2)+
                    Wg[i]*LP3$K[i]*dKdG[i]*(3*LP3$G[i]+0.75*LP3$G[i]^3)+
                    Wg[i]^2*dKdG[i]^2*(6+9*LP3$G[i]^2+1.875*LP3$G[i]^4))/M[i,j] + 
                (1-Wg[i])^2*Yhat.SigReg[i]^2*MSEGR*dKdG[i]^2
            } else { # if normal GLS, use Eq 19.
              Omega[i,j] <-  GSQ + Yhat.SigReg[i]^2*
                (1+LP3$K[i]*LP3$G[i]+0.5*LP3$K[i]^2*
                    (1+0.75*LP3$G[i]^2))/M[i,j]
            }
          } else { # Off-diagonal elements of weighting matrix
            if (SkewAdj) { # if skew-adjusted GLS, use Eq 22 (correct manual to match Giffis and Stedinger (2007) Eq 5; WREG v1.05 code is correct)
              Omega[i,j] <- Rhos[i,j]*Yhat.SigReg[i]*Yhat.SigReg[j]*M[i,j]*
                (1+0.5*LP3$K[i]*LP3$G[i]+0.5*LP3$K[j]*LP3$G[j]+
                    0.5*LP3$K[i]*LP3$K[j]*(Rhos[i,j]+0.75*LP3$G[i]*LP3$G[j])+
                    0.5*Wg[j]*LP3$K[i]*LP3$G[j]*dKdG[j]*(3*Rhos[i,j]+0.75*LP3$G[i]*LP3$G[j])+
                    0.5*Wg[i]*LP3$K[j]*LP3$G[i]*dKdG[i]*(3*Rhos[i,j]+0.75*LP3$G[i]*LP3$G[j])+
                    Wg[i]*Wg[j]*Yhat.SigReg[i]*Yhat.SigReg[j]*dKdG[i]*dKdG[j]*Covgg[i,j])/M[i,i]/M[j,j]
            } else { # if normal GLS, use Eq 19.
              Omega[i,j] <- Rhos[i,j]*Yhat.SigReg[i]*Yhat.SigReg[j]*M[i,j]*
                (1+0.5*LP3$K[i]*LP3$G[i]+0.5*LP3$K[j]*LP3$G[j]+
                    0.5*LP3$K[i]*LP3$K[j]*(Rhos[i,j]+0.75*LP3$G[i]*LP3$G[j]))/M[i,i]/M[j,j]
            }
          }
        }
      }
      B_hat <- solve(t(X)%*%solve(Omega)%*%X)%*%t(X)%*%solve(Omega)%*%Y # Use weighting matrix to estimate regression coefficients
      Iterations2$Deviation[w] <- t(Y-X%*%B_hat)%*%solve(Omega)%*%(Y-X%*%B_hat)-Target # Difference between result and target value. Eq 21.
    }
    BestPos <- which(Iterations2$Deviation==min(Iterations2$Deviation[Iterations2$Deviation>0])) # Find minimum positive deviation from Eq 21.
    GSQ <- Iterations2$GSQ[BestPos] # best estimate of model-error variance
  }
  ## Calculate Final Omega (weighting matrix)
  for (i in 1:length(Y)) {
    for (j in 1:length(Y)) {
      if (i==j) { # Diagonal elements of weighting matrix
        if (SkewAdj) { # if skew-adjusted GLS, use Eq 22 (correct manual to match Giffis and Stedinger (2007) Eq 5; WREG v1.05 code is correct)
          Omega[i,j] <-  GSQ + 
            Yhat.SigReg[i]^2*(1+LP3$K[i]*LP3$G[i]+
                0.5*LP3$K[i]^2*(1+0.75*LP3$G[i]^2)+
                Wg[i]*LP3$K[i]*dKdG[i]*(3*LP3$G[i]+0.75*LP3$G[i]^3)+
                Wg[i]^2*dKdG[i]^2*(6+9*LP3$G[i]^2+1.875*LP3$G[i]^4))/M[i,j] + 
            (1-Wg[i])^2*Yhat.SigReg[i]^2*MSEGR*dKdG[i]^2
        } else { # if normal GLS, use Eq 19.
          Omega[i,j] <-  GSQ + Yhat.SigReg[i]^2*
            (1+LP3$K[i]*LP3$G[i]+0.5*LP3$K[i]^2*
                (1+0.75*LP3$G[i]^2))/M[i,j]
        }
      } else { # Off-diagonal elements of weighting matrix
        if (SkewAdj) { # if skew-adjusted GLS, use Eq 22 (correct manual to match Giffis and Stedinger (2007) Eq 5; WREG v1.05 code is correct)
          Omega[i,j] <- Rhos[i,j]*Yhat.SigReg[i]*Yhat.SigReg[j]*M[i,j]*
            (1+0.5*LP3$K[i]*LP3$G[i]+0.5*LP3$K[j]*LP3$G[j]+
                0.5*LP3$K[i]*LP3$K[j]*(Rhos[i,j]+0.75*LP3$G[i]*LP3$G[j])+
                0.5*Wg[j]*LP3$K[i]*LP3$G[j]*dKdG[j]*(3*Rhos[i,j]+0.75*LP3$G[i]*LP3$G[j])+
                0.5*Wg[i]*LP3$K[j]*LP3$G[i]*dKdG[i]*(3*Rhos[i,j]+0.75*LP3$G[i]*LP3$G[j])+
                Wg[i]*Wg[j]*Yhat.SigReg[i]*Yhat.SigReg[j]*dKdG[i]*dKdG[j]*Covgg[i,j])/M[i,i]/M[j,j]
        } else { # if normal GLS, use Eq 19.
          Omega[i,j] <- Rhos[i,j]*Yhat.SigReg[i]*Yhat.SigReg[j]*M[i,j]*
            (1+0.5*LP3$K[i]*LP3$G[i]+0.5*LP3$K[j]*LP3$G[j]+
                0.5*LP3$K[i]*LP3$K[j]*(Rhos[i,j]+0.75*LP3$G[i]*LP3$G[j]))/M[i,i]/M[j,j]
        }
      }
    }
  }
  ## Control output
  GLS.Weights <- list(GSQ=GSQ,Omega=Omega) # Output contains model-error variance and weighting matrix.
  return(GLS.Weights)
}