library(devtools)
system('dx download file-GP7pZ9jJqYjVzqxY5B4qf1zV')
baseline_table=read.csv('data_participant.csv')

names(baseline_table)=c('eid','hba1c','glucose','recruit_age','mob','yob','sex','bmi','waist','hip','alcohol_status','alcohol_freq','pack_years','smoking_status','cigs_per_day','assess_date','height')
baseline_table$mob=match(baseline_table$mob, month.name) 
baseline_table=baseline_table%>%mutate(dob=as.Date(paste(yob,mob,15,sep='/')))

baseline_table=mutate(baseline_table,assess_date=as.Date(assess_date))
baseline_table=mutate(baseline_table,assess_age=as.numeric(assess_date-dob)/365.25)

baseline_table=baseline_table[,c(1,7,19,18,8,9,10,2,3,14,13,15,11,12)]
