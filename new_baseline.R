library(dplyr)

get_baseline_dict <- function(){
  # set project and record ID. TODO call these from context IDs
  projectid <- "project-GbZ9g7QJVJzZVQj45j6xgxZ8"
  rid <- "record-Gbf3bQjJbPb6Bgq60z0z2VVq"
  # Assign joint dataset project-id:record-id
  dataset <- glue::glue("{projectid}:{rid}")
  
  # get dataset
  cmd <- glue::glue("dx extract_dataset {dataset} -ddd")
  system(cmd)
  
  data_dict_file <- list.files(pattern="*.data_dictionary.csv")
  data_dict_df <- read_csv(data_dict_file, show_col_types = FALSE)
}

lookup_pheno <- function(string_to_get){
  data_dict_df %>%
    select(entity, name, title, type) %>% 
    filter(grepl(string_to_get,title))
}

get_baseline <- function(phenos_to_get){
  # read in data dictionary
  data_dict_df <- data_dict_df %>%
    relocate(name, title) %>%
    mutate(ent_field = glue::glue("{entity}.{name}"))
  # filter to phenos to get
  filtered_dict <- data_dict_df %>%
    filter(name %in% phenos_to_get) %>%
    arrange(title) 
  # fitler to field names
  field_list_full <- filtered_dict %>%
    pull(ent_field)
  # create list of fields to pull
  field_list <- paste(field_list_full, collapse = ",")
  field_list <- paste0("participant.eid,", field_list)
  # pull out phenotypes in loop
  step=25 # do 25 at a time otherwise it'll timeout
  for(i in seq(1,length(field_list_full),by=step)){
    upper_lim=i+step-1
    if(upper_lim>length(field_list_full)){
        upper_lim=length(field_list_full)
    }
    # subset to the fields we want this time
    field_list <- paste(field_list_full[i:upper_lim], collapse = ",")
    field_list <- paste0("participant.eid,", field_list)
    cohort_template <- glue::glue("dx extract_dataset {dataset} --fields {field_list} -o cohort_data",i,".csv")
    cmd <- glue::glue(cohort_template)
    #print(cmd)
    system(cmd)
  }
  # read in data
  for(i in seq(1,length(field_list_full),by=step)){
    if(i == 1){
      baseline_data <- read_csv(paste0("cohort_data",i,".csv"))
    }else{
      baseline_data %<>% left_join(read_csv(paste0("cohort_data",i,".csv")))
    }
  }
  # remove "participant." from field names
  names(baseline_data) <- gsub("participant.","",names(baseline_data))
  # return the dataframe
  baseline_data
}

#names(baseline_table)=c('eid','recruit_age','mob','yob','sex','tdi','ethnicity','alcohol','alcohol_freq','former_alcohol','ever_smoked','pack_years','smoking_status','current_smoking','father_illness','mother_illness','overall_health','ever_psa','ever_bowel_cancer_screening','recent_bowel_cancer_screening','time_since_psa','diabetes_diagnosed','gestational_diabetes','age_diabetes_diagnosed','ins_1_year','cancer_diagnosed','chol_med','chol_hormone_med','prescription_meds','had_menopause','age_menopause','age_menarche','fluid_intelligence','matches_time','birth_weight','diastolic_blood_pressure','diastolic_blood_pressure_manual','systolic_blood_pressure','height','waist','weight','bmi','hip','standing_height','body_fat','heel_BMD_manual','heel_sound_speed','heel_BMD','glucose','hba1c','hdl_cholesterol','ldl_cholesterol','total_cholesterol','blood_type','assess_date','centre')
#
#baseline_table$mob=match(baseline_table$mob, month.name) 
#baseline_table=baseline_table%>%mutate(dob=as.Date(paste(yob,mob,15,sep='/')),assess_date=as.Date(assess_date))
#baseline_table=mutate(baseline_table,assess_age=as.numeric(assess_date-dob)/365.25,whr=waist/hip)
