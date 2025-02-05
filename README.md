# UKBB Health Care Records

This repository contains an ensemble of functions for use analysing the UKBB records on DNA Nexus.

**Terms of use:** This software has been provided free of charge for the academic community. In return, the only requirement is that you make your code openly available in kind for any paper that uses my functions, and acknowledge (ideally, cite) this repository in your work.

# Available Functions

`read_GP` Reads data from the GP clinical records. It takes a list of read3 or read2 codes and returns one line per matching record, including eid date, value, and read code

`read_OPCS` Reads OPCS codes from the operation records. It takes a list of OPCS codes and returns eid, opdate and code for each matching record

`read_ICD10` Reads data from the HES records using ICD10. It performs an inner join on the diagnosis and returns the eid, code, in date, out date, and whether it was a primary or secondary diagnosis

`read_ICD9` Reads data from the HES records using ICD9. It performs an inner join on the diagnosis but there is no data on ICD9 dates of diagnosis in the UKBB HES records

`read_cancer` Reads data from the Cancer Registry data using ICD10. It returns the eid, date, and cancer type

`read_selfreport` Reads data from the UK Biobank's non-cancer self-reported illness codes. It takes a list of codes from https://biobank.ctsu.ox.ac.uk/crystal/coding.cgi?id=6 and returns a list of matching IDs

`read_selfreport_cancer` Reads data from the UK Biobank's cancer self-reported illness codes. It takes a list of codes from https://biobank.ctsu.ox.ac.uk/crystal/coding.cgi?id=3 and returns a list of matching IDs

`first_occurence` takes a list of ICD10, read3, OPCS and cancer ICD10 codes and returns the date and source of the first occurrence of disease. It does not use ICD9, because the dates are not present in these records.


# How to Use

## Setup

On an RStudio Workbench session on DNA Nexus, on project 103356 run

```
library(devtools) 
source_url("https://raw.githubusercontent.com/hdg204/UKBB/main/UKBB_Health_Records_New_Project.R") 
```

On 9072, run

```
library(devtools) 
source_url("https://raw.githubusercontent.com/hdg204/UKBB/main/UKBB_Health_Records_Public.R") 
```

This will copy all files from the project directory onto your R session and make all functions available for use in R. This should take somewhere between 90 seconds and 2 minutes.

**Please only install one version of the package. There will be compatibility issues if you have files from one version and code from another.**

## Extracting Healthcare Records

Running, for example

```
ICD10_codes=c('E10','E11')
ICD10_records=read_ICD10(ICD10_codes)
```

will return a dataframe `ICD10_records` which will contain all HES records that match either E10 (Insulin-dependent diabetes mellitus) oe E11 (Non-insulin-dependent diabetes mellitus). This can also be run on sub codes, e.g. E11.3, for Diabetic Retinopathy. The other read functions work much the same way. The input to `read_ICD10`, `read_OPCS`, `read_GP` and `read_cancer` must be a string or a list of strings.

These functions will always output a dataframe with the same columns. If it doesn't find anything, it will output a dataframe with no rows. If you give it '' as an input, it will also return a dataframe with no rows. This can be useful if you need to run the command but you don't have any matching codes.

The self-report data can be extracted using, e.g. `read_selfreport(1065)`. The self-report functions require numerical inputs

## Combining Healthcare Sources

Many phenotypes can be defined in a variety of ways. Frozen Shoulder can be defined by ICD10 code M75.0, GP codes N210., XE1FL, and XE1Hm or OPCS4 code W78.1.

The function `first_occurence` can take ICD, GP, OPCS, and cancer registry codes (also ICD10) and output the first date the phenotype appears and where it first appears. Running 

```
frozen_shoulder = first_occurence(ICD10 = 'M75.0', GP = c("N210.","XE1FL","XE1Hm"), OPCS = 'W78.1', cancer='')
```

will return a dataframe with three columns: the id, the date of first frozen shoulder record, and the source that appeared in. For this phenotype, I don't need to query the cancer registry, so '' is used as the input.

## Longitudinal Primary Care Records

`read_GP` preserves the value from the GP records and can be used for longitudinal analysis. Using the read_3 code 22K.. for BMI, you can run `read_GP('22K..')` (this is a little bit slow because the GP records are 5GB) and it will return all BMI recordings in the GP records.

These are longitudinal and have the date in event_dt and the actual BMI value in value_1, value_2 or value_3.

## Combining with Baseline Data

As long as you have a CSV with an eid column, the output of any of these scripts can be easily joined with baseline data. I would recommend appending a column to the records with the phenotype as a 1. E.g. if you have a dataframe in R with the baseline data called `baseline`, then you can run

```
frozen_shoulder = first_occurence(ICD10 = 'M75.0', GP = c("N210.","XE1FL","XE1Hm"), OPCS = 'W78.1', cancer='')
frozen_shoulder = mutate(frozen_shoulder, FS=1)
all_data = full_join(baseline, frozen_shoulder)
```

`all_data` will now contain the frozen shoulder records, with a column `FS` which is 1 if they were in the record and NA if they weren't. `all_data$FS[is.na(all_data$FS)]=0` will turn all the NAs into 0s.

# Known issues

The script relies on grepping entire lines from a CSV. As ICD9 codes are purely numeric, these can match on participant IDs and cannot currently be read in. I'm working on replacing the grep with an awk command which should address this issue and allow ICD9 codes to be read.

The line level grep might also accidentally tag other things that happen to match. This is still in testing and I'd recommend looking at the data to check there isn't anything in there you don't want.

# For users from outside the University of Exeter

The code in this repository has been written to run from Exeter's application 103356. If you are not an Exeter user, you will need to generate the files yourself. Below is a readme for creating the necessary tables to run `read_ICD10` and `read_OPCS` from the HES records. A similar process can be followed for GP, death and cancer.

In your base directory, click on the dataset:

<img src="https://github.com/user-attachments/assets/dd54e34c-ca48-4479-a06c-a0f90e1cb4a1" alt="Your image title" width="750"/>

Click on data preview, and then add column, and you should be able to active a drop down:

<img src="https://github.com/user-attachments/assets/f9b50efe-43db-4096-9e5f-5419b9aa6971" alt="Your image title" width="350"/>
 
Add the following columns from record-level access:
*	Hospitalisation Record
    *	Participant ID
    *	Instance index
    * Inpatient record origin
    *	Inpatient record format
    *	Episode start date
    *	Episode end date
    *	Duration of episode
    *	(You can add others if they interest you)
*	Hospital Diagnosis Record
    * All columns
*	Hospital Operation Record
    * All Columns
 	
Your screen should look something like this

<img src="https://github.com/user-attachments/assets/cff17c1c-5473-402f-b290-445427d05f28" alt="Your image title" width="750"/>
 
Save the cohort in a sensible place. Then  start a new analysis and click on the table exporter and set up a run that looks like the following, where record is the cohort you just saved. Make sure all options contain the same (except the record ID, which will be different for you):

<img src="https://github.com/user-attachments/assets/de3bf844-8998-4241-b20a-ad4fd4b5d131" alt="Your image title" width="300"/>

When this has run, you’ll get an email and you should see the following files wherever you told it to output them:

<img src="https://github.com/user-attachments/assets/51987fa8-c419-473f-879b-e0851bd7ccf4" alt="Your image title" width="750"/>

You won’t have hesin_critical though, I took that out because it wasn’t… er… critical. How ironic.

This will give you csv files of all of the HES records in UKBB. These are the files my code is looking for. However, the file IDs will not work for you. In the following lines of UKBB_Health_Records_New_Project.R, you’ll need to change the following lines to use your own file IDs (shown right of picture above)

```
system('dx download file-Gp36v5jJ0qKKgQXxxQ0gjf0f') # download HES Diagnoses
system('dx download file-Gp36v5QJ0qKJv0pQ0X5Z2B5K') # download HES Records
system('dx download file-Gp36v5jJ0qK58yQkJ06gzGvv') # download OPCS Records
```
