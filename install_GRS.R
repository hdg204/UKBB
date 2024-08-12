system('curl https://raw.githubusercontent.com/hdg204/UKBB/main/GRS_step_1.sh > GRS_step_1.sh')
system('curl https://raw.githubusercontent.com/hdg204/UKBB/main/GRS_step_2.sh > GRS_step_2.sh')
system('chmod +777 GRS_step_1.sh')
system('chmod +777 GRS_step_2.sh')
system('./GRS_step_1.sh')
system('curl https://raw.githubusercontent.com/hdg204/Rdna-nexus/main/Example_GRS > Example_GRS')

library('dplyr')
library('devtools')
generate_grs=function(infile){
  system(paste('./GRS_step_2.sh', infile))
  score=read.csv('score.profile',sep='')
  score=score%>%rename(eid=FID,score=SCORE)%>%select(eid,CNT,CNT2,score)
    
  
  #first apply QC steps. These commands find all the relevant information in the mfi files but only for the SNPs in the GRS
  for (i in 1:22){
      system(paste0("awk '$1 == ",i," {print $2}' ", infile, " | grep -w -f - ../../mnt/project/Bulk/Imputation/UKB\\ imputation\\ from\\ genotype/ukb22828_c",i,"_b0_v3.mfi.txt>infotemp"))
      system(paste0("awk '{print $0, ",i,"}' infotemp >> info"))
  }
  system(paste0("awk '$1 == ",23," {print $2}' ", infile, " | grep -w -f - ../../mnt/project/Bulk/Imputation/UKB\\ imputation\\ from\\ genotype/ukb22828_cX_b0_v3.mfi.txt>infotemp"))
  system(paste0("awk '{print $0, ",23,"}' infotemp >> info"))
  system(paste0("awk '$1 == ",23," {print $2}' ", infile, " | grep -w -f - ../../mnt/project/Bulk/Imputation/UKB\\ imputation\\ from\\ genotype/ukb22828_cX_b0_v3.mfi.txt>infotemp"))
  system(paste0("awk '{print $0, ",23,"}' infotemp >> info"))
  info=read.csv('info',sep='',header=F)
  info=info%>%rename(ID=V1,rsid=V2,MAF=V6,info=V8)%>%select(ID,rsid,MAF,info)
  return(c(score,info))
}

