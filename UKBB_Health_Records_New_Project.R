# This script copies data from the DNA Nexus project into your RStudio Workbench session, and then loads in three functions for reading in phenotypes:
# read_gp will read data from the gp records using read_3 or read_2 codes
# read_OPCS will read data from the operations records using OPCS4 codes
# read_ICD10 will read data from the HES records using ICD10 codes
# A tutorial on how to use these functions is available on teams, or from Harry Green (h.d.green@exeter.ac.uk)

# While the functions are designed to take the codes above, since all of the filtering relies on a system-level grep it is also possible to filter on a participant ID instead of a healthcare code.

library('dplyr')

# First download my files into the R session. You can delete lines if data source not necessary, but it's fairly fast even if you don't
system('dx download file-GZKXxpQJKVzZ0BgzQZ1YYj9Z') # download GP registrations
system('dx download file-GZKXxpQJKVzVb7gQvQbYfxKF') # download GP clinical
system('dx download file-GZKXxpQJKVzxKb0FYfGg28v9') # download GP scripts
system('dx download file-GZKXVqjJX72FFKKVYKqfj40z') # download HES Diagnoses
system('dx download file-GZKXVqjJX729j2vjbGb0BYfJ') # download HES Records
system('dx download file-GZKXVqjJX72JPkx613V5XxYB') # download OPCS Records
system('dx download file-GZKXgQjJY2Fkg1ZG4Bg8ZJBP') # download Cancer_Registry
system('dx download file-GZJKVv8J9qP9xGfpK5KpP5G9') # download self report
#system('dx download file-GFVkYq8JZ8kk76Kg0GG7yq5K') # download treatment - this is embedded in self report in the new file
system('dx download file-GZJ9bbQJj59YBg8j4Kffpx9v') # download data coding 3
system('dx download file-GZJ9Z98Jj59YBg8j4Kffpx78') # download data coding 4
system('dx download file-GZJ9Z98Jj59gQ0zX6p3Jx3p9') # download data coding 6

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
	opcs_header=c('dnx_hesin_oper_id','eid','ins_index','arr_index','opdate','level','oper3','oper3_nb','oper4','oper4_nb','posopdur','preopdur')
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
	colnames(data)=c('dnx_hesin_diag_id','eid','ins_index','arr_index','classification','diag_icd9','diag_icd9_add','diag_icd10','diag_icd10_add')
	#I think that the ins index is an index for that hospital admission so joining on those should add the dates
	data=data%>%select(dnx_hesin_diag_id,eid,ins_index,arr_index,classification,diag_icd9,diag_icd10)
	records=read.csv(recordfile)
	data2=inner_join(data,records)
	data2=data2%>%mutate(epistart=as.Date(epistart),epiend=as.Date(epiend))
	return(data2)
}

# read_ICD9 is also complicated by the fact that the codes are often just numerical, which is more likely to provide false matches than an A00.0 type code
read_ICD9 <- function(codes,diagfile='HES_hesin_diag.csv',recordfile='HES_hesin.csv') {
	icd9_header=c('dnx_hesin_diag_id','eid','ins_index','arr_index','level','diag_icd9','diag_icd10','dnx_hesin_id','epistart','epiend')
	codes=as.character(codes)
	if(codes[1]==''){
		return(read.table(text = "",col.names = icd9_header))
	}
	codes2=paste(codes,collapse='\\|')
	grepcode=paste('grep \'',codes2,'\' ', diagfile, '> temp.csv',sep='')
	system(grepcode)
	if (as.numeric(file.info('temp.csv')[1])==0){
		return(read.table(text = "",col.names = icd9_header))
	}
	data=read.csv('temp.csv',header=FALSE)
	colnames(data)=c('dnx_hesin_diag_id','eid','ins_index','arr_index','classification','diag_icd9','diag_icd9_add','diag_icd10','diag_icd10_add')
	#I think that the ins index is an index for that hospital admission so joining on those should add the dates
	data=data%>%select(dnx_hesin_diag_id,eid,ins_index,arr_index,classification,diag_icd9,diag_icd10)
	
	#this makes a vector of everything before the space
	icd9_code_data=sapply(strsplit(data$diag_icd9, " "), function(x) x[1])
	
	#make a vector of falses
	vec=rep(FALSE,length(icd9_code_data))
	#if the code is at the start of the icd9 codes, make that vector true
	
	for (j in 1:length(codes)){
		vec=vec+grepl(paste0("^", codes[j]), icd9_code_data)		
	}
	vec=vec>0.5
	data=data[vec,]
	
	
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
	ids=rep(data[,1],22) # there are 17 different cancer columns in UK Biobank's data, this works by stretching the 17xn columns into a 1 x 22*n one dimensional structure
	
	datesvars <- list()
	cancersvars <- list()
	agevars <- list()
	histologyvars <- list()
	behaviourvars <- list()

	# Create a loop to generate the list elements
	for (i in 0:21) {
		datesvars[i+1] <- paste0('p40005_i', i)
		cancersvars[i+1] <- paste0('p40006_i', i)
		agevars[i+1] <- paste0('p40008_i', i)
		histologyvars[i+1] <- paste0('p40011_i', i)
		behaviourvars[i+1] <- paste0('p40012_i', i)
	}
	
	dateslist=unlist(data[,unlist(datesvars)])
	cancerslist=unlist(data[,unlist(cancersvars)])
	agelist=unlist(data[,unlist(agevars)])
	histologylist=unlist(data[,unlist(histologyvars)])
	behaviourlist=unlist(data[,unlist(behaviourvars)])


	data=data.frame(eid=ids,date=dateslist,site=cancerslist,age=agelist,histology=histologylist,behaviour=behaviourlist)%>%mutate(date=as.Date(date))
	codes3=paste(codes,collapse='|')
	data=data[grep(codes3,data$site),] #if someone does have multiple cancers, now everything is one cancer per line, this grep will get rid of those records

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

read_treatment <- function(codes,file='treatment_participant.csv'){
	data=read.csv(file)
	coding4=read.csv('coding4.tsv',sep='\t')%>%filter(coding>1)
	outlines=NULL
	for (i in 1:length(codes)){
		if (length(coding4[coding4$coding==codes[1],'meaning'])>0){
			outlines=c(outlines,grep(coding4[coding4$coding==codes[i],'meaning'],data$Treatment.medication.code...Instance.0))
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


# This function reads GP scripts in from the file GP_gp_scripts.csv. It first greps the file through system so it doesn't read in any of the wrong codes. I have experimented with a few different options for this and I found this to be the fastest
read_GP_scripts <- function(codes,file='GP_gp_scripts.csv') {
  gp_header=c('eid','data_provider','issue_date','read_2','dmd_code','bnf_code','drug_name','quantity') # this is the names of all the columns that will be outputted
  
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
  colnames(data)=gp_header
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