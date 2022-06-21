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

# Known issues

The script relies on grepping entire lines from a CSV. As ICD9 codes are purely numeric, these can match on participant IDs and cannot currently be read in. I'm working on replacing the grep with an awk command which should address this issue and allow ICD9 codes to be read
