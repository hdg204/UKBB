# This script copies data from the DNA Nexus project into your RStudio Workbench session, and then loads in three functions for reading in phenotypes:
# read_gp will read data from the gp records using read_3 or read_2 codes
# read_OPCS will read data from the operations records using OPCS4 codes
# read_ICD10 will read data from the HES records using ICD10 codes
# A tutorial on how to use these functions is available on github, or from Harry Green (h.d.green@exeter.ac.uk)

# While the functions are designed to take the codes above, since all of the filtering relies on a system-level grep it is also possible to filter on a participant ID instead of a healthcare code.

library('dplyr')

# First download my files into the R session. You can delete lines if data source not necessary, but it's fairly fast even if you don't
system('dx download file-GBZy48QJQFKk9XZx9gZjjXKv') # download GP records
system('dx download file-GBZxv8jJG9GkV0GYJVFFXY43') # download HES Diagnoses
system('dx download file-GBZxv8jJG9GZ2Qqz1825052Z') # download HES Records
system('dx download file-GBZxv8jJG9Gpq9J38bkFf9k8') # download OPCS Records
system('dx download file-GBZxjv0JQX22ZZX18yx1995G') # download Cancer_Registry
system('dx download file-GBjk2V0J6G86jK7vJYxKp0JX') # download self report
system('dx download file-GBjk0BjJZ8kX2J79Gqk3XkB6') # download self report data indices
system('dx download file-GBjk0BjJZ8kp68JG77Q1QY38') # download self report data indices


# This function reads GP records in from the file GP_gp_clinical.csv. It first greps the file through system so it doesn't read in any of the wrong codes. I have experimented with a few different options for this and I found this to be the fastest
read_GP <- function(codes,file='GP_gp_clinical.csv') {
	gp_header=c('eid', 'data_provider', 'event_dt', 'read_2', 'read_3', 'value1', 'value2', 'value3') # this is the names of all the columns that will be outputted
	
	#check if there are any codes inputted, if not, just return an empty dataframe with the correct headers
	if (codes[1]==''){
		return(read.table(text = "",col.names = gp_header))
	}
	
	codes2=paste(codes,collapse='\\|') #turn, e.g. 'code1,code2 into code1\\|code2 for use in a grep
	grepcode=paste('grep \'',codes2,'\' ', file, '> temp.csv',sep='') #build a grep command using paste
	system(grepcode) #grep all codes inputted from the GP clinical table into temp.csv
	
	#if the file temp.csv is empty, return the empty dataframe
	if (as.numeric(file.info('temp.csv')[1])==0){
		return(read.table(text = "",col.names = gp_header))
	}
	
	data=read.csv('temp.csv',header=FALSE)
	colnames(data)=c('eid', 'data_provider', 'event_dt', 'read_2', 'read_3', 'value1', 'value2', 'value3')
	data=data%>%mutate(event_dt=as.Date(event_dt)) #turn event_dt into a date variable
	
	#because of .s in GP code, other stuff might have been read in due to the grep, so I need a secondary filter here
	data2=NULL
	for (i in 1:length(codes)){
		data2=rbind(data2,filter(data,read_3==codes[i]))
		data2=rbind(data2,filter(data,read_2==codes[i]))
	}
	return(data2)
}

# This is basically a copy paste of the above script and works in the same way but for OPCS codes
read_OPCS <- function(codes,filename='HES_hesin_oper.csv') {
	opcs_header=c('dnx_hesin_oper_id','eid','ins_index','arr_index','level','opdate','oper3','oper4')
	if(codes[1]==''){
		return(read.table(text = "",col.names = opcs_header))
	}
	codes2=paste(codes,collapse='\\|')
	grepcode=paste('grep \'',codes2,'\' ', filename, '> temp.csv',sep='')
	system(grepcode)
	if (as.numeric(file.info('temp.csv')[1])==0){
		return(read.table(text = "",col.names = opcs_header))
	}
	data=read.csv('temp.csv',header=FALSE)
	colnames(data)= opcs_header
	data=data%>%mutate(opdate=as.Date(opdate))
	return(data)
}

# The ICD10 funciton is a bit more complicated because the diagnosis table does not contain the dates. As a result, there are two different headers to deal with
read_ICD10 <- function(codes,diagfile='HES_hesin_diag.csv',recordfile='HES_hesin.csv') {
	icd10_header=c('dnx_hesin_diag_id','eid','ins_index','arr_index','level','diag_icd9','diag_icd10','dnx_hesin_id','epistart','epiend')
	if(codes[1]==''){
		return(read.table(text = "",col.names = icd10_header))
	}
	codes2=paste(codes,collapse='\\|')
	grepcode=paste('grep \'',codes2,'\' ', diagfile, '> temp.csv',sep='')
	system(grepcode)
	if (as.numeric(file.info('temp.csv')[1])==0){
		return(read.table(text = "",col.names = icd10_header))
	}
	data=read.csv('temp.csv',header=FALSE)
	colnames(data)=c('dnx_hesin_diag_id','eid','ins_index','arr_index','level','diag_icd9','diag_icd10')
	#I think that the ins index is an index for that hospital admission so joining on those should add the dates
	records=read.csv(recordfile)
	data2=inner_join(data,records)
	data2=data2%>%mutate(epistart=as.Date(epistart),epiend=as.Date(epiend))
	return(data2)
}

read_cancer <- function(codes,file='cancer_participant.csv') {
	#this function reads from the cancer registry, which is in a wide format and requires a much different way of extracting the data
	cancer_header=c('eid','date','cancer')
	if(codes[1]==''){
		return(read.table(text = "",col.names = cancer_header))
	}
	codes2=paste(codes,collapse='\\|')
	grepcode=paste('grep \'',codes2,'\' ', file, '> temp.csv',sep='') #it is possible that this will grep out other cancers too, if someone has multiple, as this extracts lines not columns
	system(grepcode)
	if (as.numeric(file.info('temp.csv')[1])==0){
		return(read.table(text = "",col.names = cancer_header))
	}
	data=read.csv('temp.csv',header=FALSE)
	colnames(data)=colnames(read.csv(file="cancer_participant.csv",nrows=1))
	ids=rep(data[,1],17) # there are 17 different cancer columns in UK Biobank's data, this works by stretching the 17xn columns into a 1 x 17*n one dimensional structure
	dateslist=unlist(data[,c('p40005_i0','p40005_i1','p40005_i2','p40005_i3','p40005_i4','p40005_i5','p40005_i6','p40005_i7','p40005_i8','p40005_i9','p40005_i10','p40005_i11','p40005_i12','p40005_i13','p40005_i14','p40005_i15','p40005_i16')])
	cancerslist=unlist(data[,c('p40006_i0','p40006_i1','p40006_i2','p40006_i3','p40006_i4','p40006_i5','p40006_i6','p40006_i7','p40006_i8','p40006_i9','p40006_i10','p40006_i11','p40006_i12','p40006_i13','p40006_i14','p40006_i15','p40006_i16')])
	data=data.frame(eid=ids,date=dateslist,cancer=cancerslist)%>%mutate(date=as.Date(date))
	codes3=paste(codes,collapse='|')
	data=data[grep(codes3,data$cancer),] #if someone does have multiple cancers, now everything is one cancer per line, this grep will get rid of those records
	return(data)
}

read_selfreport <- function(codes,file='selfreport_participant.csv'){
	data=read.csv(file)
	coding6=read.csv('coding6.tsv',sep='\t')%>%filter(coding>1)
	outlines=NULL
	for (i in 1:length(codes)){
		if (length(coding6[coding6$coding==codes[1],'meaning'])>0){
			outlines=c(outlines,grep(coding6[coding6$coding==codes[i],'meaning'],data$p20002_i0))
		}
	}
	data_frame=data.frame(eid=data[outlines,1])
	return(data_frame)
}

read_selfreport_cancer <- function(codes,file='selfreport_participant.csv'){
	data=read.csv(file)
	coding3=read.csv('coding3.tsv',sep='\t')%>%filter(coding>1)
	outlines=NULL
	for (i in 1:length(codes)){
		if (length(coding3[coding3$coding==codes[1],'meaning'])>0){
			outlines=c(outlines,grep(coding3[coding3$coding==codes[i],'meaning'],data$p20001_i0))
		}
	}
	data_frame=data.frame(eid=data[outlines,1])
	return(data_frame)
}

first_occurence=function(ICD10='',GP='',OPCS='',cancer=''){
    ICD10_records=read_ICD10(ICD10)%>%mutate(date=epistart)%>%select(eid,date)%>%mutate(source='HES')
    OPCS_records=read_OPCS(OPCS)%>%mutate(date=opdate)%>%select(eid,date)%>%mutate(source='OPCS')
    GP_records=read_GP(GP)%>%mutate(date=event_dt)%>%select(eid,date)%>%mutate(source='GP')
    cancer_records=read_cancer(cancer)%>%select(eid,date)%>%mutate(source='Cancer_Registry')
    all_records=rbind(ICD10_records,OPCS_records)%>%rbind(GP_records)%>%rbind(cancer_records)%>%mutate(date=as.Date(date))
    all_records=all_records%>%group_by(eid)%>%top_n(-1,date)%>%distinct()
	return(all_records)
}


system('dx download file-GBZy48QJQFKzXbXv25xk62ff') # download GP scripts
# This function reads GP scripts in from the file GP_gp_scripts.csv. It first greps the file through system so it doesn't read in any of the wrong codes. This function was written by Jess O'Loughlin
read_GP_scripts <- function(codes) {
  gp_header=c('eid', 'read_2','bnf_code', 'dmd_code', 'drug_name', 'data_provider','issue_date','quantity') # this is the names of all the columns that will be outputted
  #check if there are any codes inputted, if not, just return an empty dataframe with the correct headers
  if (codes[1]==''){
    return(read.table(text = "",col.names = gp_header))
  }
  codes2=paste(codes,collapse='\\|') #turn, e.g. 'code1,code2 into code1\\|code2 for use in a grep
  grepcode=paste('grep \'',codes2,'\' ', file, '> temp.csv',sep='') #build a grep command using paste
  system(grepcode) #grep all codes inputted from the GP clinical table into temp.csv
  #if the file temp.csv is empty, return the empty dataframe
  if (as.numeric(file.info('temp.csv')[1])==0){
    return(read.table(text = "",col.names = gp_header))
  }
  data=read.csv('temp.csv',header=FALSE)
  colnames(data)=c('eid', 'read_2','bnf_code', 'dmd_code', 'drug_name', 'data_provider','issue_date','quantity')
  data=data%>%mutate(issue_date=as.Date(issue_date)) #turn event_dt into a date variable
  #because of .s in GP code, other stuff might have been read in due to the grep, so I need a secondary filter here
  data2=NULL
  for (i in 1:length(codes)){
    data2=rbind(data2,filter(data,dmd_code==codes[i]))
    data2=rbind(data2,filter(data,read_2==codes[i]))
    data2=rbind(data2,filter(data,bnf_code==codes[i]))
  }
  return(data2)
}



# # Below are some examples of how to read in some random codes for a few different things
# GP_codes=c('XE2eD','22K..')
# GP_records=read_GP(GP_codes)
# 
# OPCS_codes=c('Z92.4','C29.2')
# OPCS_records=read_OPCS(OPCS_codes)
# 
# #Here E11 is type 2 diabetes, and contains numerous subcodes, but because the code works on a grep it will pull all of them out. It is also possible it will grep out an ICD9 code that happens to match
# ICD10_codes=c('E11','K52.8')
# ICD10_records=read_ICD10(ICD10_codes)
