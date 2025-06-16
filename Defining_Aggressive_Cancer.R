#This script classifies prostate cancer in the UK Biobank by 3 categories, benign, unsure and aggressive. It works by looking at what happened to the person in the 2 years following their diagnosis, where x defaults to 2

library(devtools) 
library(lubridate)
library(dplyr)
x <- 2  # year cutoff

source_url("https://raw.githubusercontent.com/hdg204/UKBB/main/UKBB_Health_Records_New_Project.R") 

diag_prca=read_cancer_2(c('C61','185'))
pr_ca_death=read_death('C61')
cancer_death=read_death('C') # first just finding any death with a C in it
cancer_death=cancer_death[grepl("^C", cancer_death$cause_icd10), ] # then filtering to icd10 code starting with C for cancer

metastatic_icd10=read_cancer_2(c('C77','C78','C79','196','197','198')) # these are codes for secondary tumours
metastatic_behaviour=read_cancer_2('C')%>%filter(behaviour==6) # this is a behaviour code for a secondary tumour
metastatic_all=rbind(metastatic_behaviour,metastatic_icd10)

metastatic_death=read_death(c('C77','C78','C79'))


# Radical prostatectomy (including specific codes)
surgery <- read_OPCS(c('M61', 'M61.1', 'M61.2', 'M61.3'))
# Chemotherapy (IV, IM, unspecified)
chemotherapy <- read_OPCS(c('X70', 'X71', 'X72'))
# Radiotherapy (external, brachytherapy, planning, unspecified)
radiotherapy <- read_OPCS(c('X65', 'X66', 'X67', 'X69'))

# Helper function that flags events within a window, given a dataframe, the age column corresponding to age at that event in that dataframe, and the name of the event. Everything assumes that diag_prca is the dataframe with all the cancer diagnosis informaiton
flag_event <- function(events_df, age_col, event_name) {
  events_df %>%
    select(eid, event_age = {{ age_col }}) %>%
    inner_join(diag_prca %>% select(eid, diag_age), by = "eid") %>%
    filter(event_age - diag_age < x, event_age - diag_age >= 0) %>%
    distinct(eid) %>%
    mutate({{ event_name }} := 1)
}

# One flag per event type
cancer_death_flag     <- flag_event(cancer_death, death_age, cancer_death)
prca_death_flag       <- flag_event(pr_ca_death, death_age, prca_death)
metastatic_diag_flag  <- flag_event(metastatic_all, diag_age, metastatic_diag)
metastatic_death_flag <- flag_event(metastatic_death, death_age, metastatic_death)
chemo_flag            <- flag_event(chemotherapy, op_age, chemotherapy)
surgery_flag          <- flag_event(surgery, op_age, surgery)
radiotherapy_flag     <- flag_event(radiotherapy, op_age, radiotherapy)

# Combine with original table to make a new one called aggressive
diag_prca_aggressive <- diag_prca %>%
  left_join(cancer_death_flag,     by = "eid") %>%
  left_join(prca_death_flag,       by = "eid") %>%
  left_join(metastatic_diag_flag,  by = "eid") %>%
  left_join(metastatic_death_flag, by = "eid") %>%
  left_join(chemo_flag,            by = "eid") %>%
  left_join(surgery_flag,          by = "eid") %>%
  left_join(radiotherapy_flag,     by = "eid") %>%
  mutate_if(is.numeric, coalesce, 0)

# benign: no evidence of aggressive disease
# unsure: treated with surgery or radiotherapy or metastatic diagnosis (not death)
# aggressive: cancer death within 2 years

diag_prca_aggressive <- diag_prca_aggressive %>%
  mutate(aggressiveness = case_when(
    prca_death == 1                     ~ "prca death",
    cancer_death == 1                   ~ "cancer death",
    chemotherapy == 1                   ~ "chemo",
    surgery == 1 | radiotherapy == 1    ~ "treated (surgery/RT)",
    TRUE                                ~ "benign"
  )) %>%
  mutate(aggressiveness = factor(aggressiveness,
    levels = c("benign", "treated (surgery/RT)", "chemo", "any cancer death", "prca death"),
    ordered = TRUE
  ))
