library(devtools)
system('dx download file-GZPzVp0JkBXbqJjYZvzvkjg4')
baseline_table=read.csv('Baseline.csv')

names(baseline_table)=c('eid','recruit_age','mob','yob','sex','tdi','ethnicity','alcohol','alcohol_freq','former_alcohol','ever_smoked','pack_years','smoking_status','current_smoking','father_illness','mother_illness','overall_health','ever_psa','ever_bowel_cancer_screening','recent_bowel_cancer_screening','time_since_psa','diabetes_diagnosed','gestational_diabetes','age_diabetes_diagnosed','ins_1_year','cancer_diagnosed','chol_med','chol_hormone_med','prescription_meds','had_menopause','age_menopause','age_menarche','fluid_intelligence','matches_time','birth_weight','diastolic_blood_pressure','diastolic_blood_pressure_manual','systolic_blood_pressure','height','waist','weight','bmi','hip','standing_height','body_fat','heel_BMD_manual','heel_sound_speed','heel_BMD','glucose','hba1c','hdl_cholesterol','ldl_cholesterol','total_cholesterol','blood_type','assess_date','centre')

baseline_table$mob=match(baseline_table$mob, month.name) 
baseline_table=baseline_table%>%mutate(dob=as.Date(paste(yob,mob,15,sep='/')),assess_date=as.Date(assess_date))
baseline_table=mutate(baseline_table,assess_age=as.numeric(assess_date-dob)/365.25,whr=waist/hip)
