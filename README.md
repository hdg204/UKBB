# UKBB Health Care Records

This repository contains an ensemble of functions for use analysing the UKBB records on DNA Nexus.

# Available Functions

`read_GP` Reads data from the GP clinical records. It takes a list of read3 or read2 codes and returns one line per matching record, including eid date, value, and read code
`read_OPCS` Reads OPCS codes from the operation records. It takes a list of OPCS codes and returns eid, opdate and code for each matching record
`read_ICD10` Reads data from the HES records using ICD10. It performs an inner join on the diagnosis and returns the eid, code, in date, out date, and whether it was a primary or secondary diagnosis
`read_cancer` Reads data from the Cancer Registry data using ICD10. It returns the eid, date, and cancer type
`read_selfreport` Reads data from the UK Biobank's non-cancer self-reported illness codes. It takes a list of codes from https://biobank.ctsu.ox.ac.uk/crystal/coding.cgi?id=6 and returns a list of matching IDs
`read_selfreport_cancer` Reads data from the UK Biobank's cancer self-reported illness codes. It takes a list of codes from https://biobank.ctsu.ox.ac.uk/crystal/coding.cgi?id=3 and returns a list of matching IDs
`first_occurence` takes a list of ICD10, read3, OPCS and cancer ICD10 codes and returns the date and source of the first occurence of disease


# How to Use

## Setup

On an RStudio Workbench session on DNA Nexus, run

```
library(devtools) 
source_url("https://raw.githubusercontent.com/hdg204/UKBB/main/UKBB_Health_Records_Public.R") 
```

This will copy all files from the project directory onto your R session. This should take somewhere between 90 seconds and 2 minutes

## HES records

Run, for example

```
ICD10_codes=c('E11','K52.8')
ICD10_records=read_ICD10(ICD10_codes)
```

# Known issues

The script relies on grepping entire lines from a CSV. As ICD9 codes are purely numeric, these can match on participant IDs and cannot currently be read in. I'm working on replacing the grep with an awk command which should address this issue and allow ICD9 codes to be read
