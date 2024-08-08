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
  score=score%>%rename(eid=FID,score=SCORE)%>%select(eid,CNT1,CNT2,score)
}
