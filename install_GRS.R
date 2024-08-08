system('curl https://raw.githubusercontent.com/hdg204/UKBB/main/GRS_step_1.sh > GRS_step_1.sh')
system('curl https://raw.githubusercontent.com/hdg204/UKBB/main/GRS_step_2.sh > GRS_step_2.sh')
system('chmod +777 GRS_step_1.sh')
system('chmod +777 GRS_step_2.sh')
system('./GRS_step_1.sh)
system('curl https://raw.githubusercontent.com/hdg204/Rdna-nexus/main/Example_GRS > Example_GRS')


generate_grs=function(infile){
  system(paste('./GRS_step_2.sh', infile))
}
