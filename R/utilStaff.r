#### function to calculate initial sapwood area at crown base (A)
compA <- function(inputs){
  p_ksi = inputs[1]
  p_rhof = inputs[2]
  p_z <- inputs[3]
  Lc = inputs[4]
  A <- p_ksi/p_rhof * Lc^p_z
  return(A)
}


# Function to Compute Hc based on ksi parameter
ksiHcMod <- function(initVar){
  h <- initVar[3] - 1.3
  b <- pi * initVar[4]^2 / 40000
  p_ksi <- pCROBAS[38,initVar[1]]
  p_rhof <- pCROBAS[15,initVar[1]]
  p_z <- pCROBAS[11,initVar[1]]
  Lc <- h* ((p_rhof * b)/(p_ksi * h^p_z))^(1/(p_z-1))
  Hc <- max(0.,(h-Lc))
  return(Hc)
}

###function to replace HC NAs in initial variable initVar
findHcNAs <- function(initVar,pHcMod){
  if(is.vector(initVar)){
    if(is.na(initVar[6])){
      if(HcModV==1){
        initVar[6] <- ksiHcMod(initVar)
      }else if(HcModV==2){
        inModHc <- c(pHcMod[,initVar[1]],initVar[3],
                     initVar[4],initVar[2],initVar[5],initVar[5])
        initVar[6] <- model.Hc(inModHc)
      }
    }
  } else if(any(is.na(initVar[6,]))){
    initVar[1,][which(initVar[1,]==0)] <- 1 ###deals with 0 species ID
    HcNAs <- which(is.na(initVar[6,]))
    BAtot <- sum(initVar[5,],na.rm = T)
    if(length(HcNAs)==1){
      if(HcModV==1){
        initVar[6,HcNAs] <- ksiHcMod(initVar[,HcNAs])
      }else if(HcModV==2){
        inModHc <- c(pHcMod[,initVar[1,HcNAs]],initVar[3,HcNAs],
                     initVar[4,HcNAs],initVar[2,HcNAs],initVar[5,HcNAs],BAtot)
        initVar[6,HcNAs] <- model.Hc(inModHc)
      }
    }else{
      if(HcModV==1){
        initVar[6,HcNAs] <- apply(initVar,1,ksiHcMod)
      }else if(HcModV==2){
        inModHc <- rbind(pHcMod[,initVar[1,HcNAs]],initVar[3,HcNAs],
                         initVar[4,HcNAs],initVar[2,HcNAs],initVar[5,HcNAs],BAtot)
        initVar[6,HcNAs] <- apply(inModHc,2,model.Hc)
      }
    }
  }
  return(initVar)
}


##Height of the crown base model
model.Hc <- function(inputs){ 
  pValues=inputs[1:6]
  H=inputs[7]
  D=inputs[8]
  age=inputs[9]
  BA_sp=inputs[10]
  BA_tot=inputs[11]
  lnHc_sim <- pValues[1]+pValues[2]*log(H)+pValues[3]*D/H+
    pValues[4]*log(age)+ pValues[5]*log(BA_sp)+
    pValues[6]*(BA_sp/BA_tot)
  Hc_sim <- exp(lnHc_sim)
  return(pmax(Hc_sim,0.,na.rm = T)) 
} 
varNames  <- c('siteID','climID','sitetype','species','ETS' ,'P0','age', 'DeadWoodVolume', 'Respi_tot','GPP/1000',
               'H','D', 'BA','Hc_base','Cw','Ac','N','npp','leff','keff','lproj','ET_preles','weight',
               'Wbranch',"WfineRoots",'Litter_fol','Litter_fr','Litter_branch','Litter_wood','V',
               'Wstem','W_croot','wf_STKG', 'wf_treeKG','B_tree','Light',"Vharvested","Wharvested","soilC",
               "aSW","summerSW","Vmort","gross growth", "GPPspecies","Rh species", "NEP sp")

  getVarNam <- function(){
    return(varNames)
}


  aTmean <- function(TAir,nYears){
    Tmean = colMeans(matrix(TAir,365,nYears))
    return(Tmean)
  }

  aTampl <- function(TAir,nYears){
    monthsDays <- c(rep(1,31),rep(2,28),rep(3,31),rep(4,30),rep(5,31),rep(6,30),
                    rep(7,31),rep(8,31),rep(9,30),rep(10,31),rep(11,30),rep(12,31))
    TbyYear <- matrix(TAir,365,nYears)
    Tampl = apply(TbyYear, 2, function(x) max(aggregate(x/2,by=list(monthsDays),FUN=mean)) - min(aggregate(x/2,by=list(monthsDays),FUN=mean))  )
    return(Tampl)
  }

  aPrecip <- function(Precip,nYears){
    aP = colSums(matrix(Precip,365,nYears))
    return(aP)
  }
