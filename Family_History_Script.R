# ------------------------------------------------------------------------------
# Reformating Family History in UK Biobank into a more useful format
# This code is intended to be run on DNA Nexus using the UK Biobank on Application 103356
# Read access to Disease Phenotyping and Genetic Risk Scores is required
# The reformating of the dataframe takes about 30 seconds
# Harry Green 16/07/2025
# ------------------------------------------------------------------------------
library('dplyr')
install.packages('tidyverse')
library(tidyverse)
system('dx download file-J1qg110JXJJFQQ6p52gYgJ11')
FH=read.csv('family_history_participant.csv')

all_ids <- FH %>% distinct(eid)

# Step 2: Extract diseases into binary format
FH_diseases <- FH %>%
  pivot_longer(cols = starts_with("p"), names_to = "p", values_to = "disease") %>%
  filter(!is.na(disease), disease != "null", disease != "") %>%
  separate_rows(disease, sep = "\\|") %>%
  filter(disease != "", !is.na(disease)) %>%
  distinct(eid, disease) %>%
  mutate(value = 1) %>%
  pivot_wider(names_from = disease, values_from = value, values_fill = list(value = 0)) %>%
  rename_with(~paste0("FH_", .x), .cols = -eid)  # add FH_ prefix to disease columns only

# Step 3: Join back to retain all eids
FH_reformat <- all_ids %>% left_join(FH_diseases, by = "eid")

FH_reformat <- FH_reformat %>%
  rename_with(~gsub(" ", "_", .x))

FH_reformat$n_FH_answers=(FH[,2]=='')+(FH[,3]=='')+(FH[,3]=='')+(FH[,4]=='')
