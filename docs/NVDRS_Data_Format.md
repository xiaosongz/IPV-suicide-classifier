# NVDRS Data Format Guide

This document describes the required data format and variables needed to run the IPV-Related Suicide Classifier on your NVDRS data.

## Overview

The IPV classifier requires NVDRS Restricted Access Database (RAD) data in `.Rdata` format containing specific variables with exact naming conventions. All variable names must be lowercase, and circumstance variables must have the `_c` suffix.

## Required Data Structure

Your NVDRS data file should be an R data frame saved as an `.Rdata` file with the following characteristics:

1. **File Format**: `.Rdata` file containing a single data frame object
2. **Case Type**: Only single suicide incidents (incidentcategory_c == "Single suicide")
3. **Variable Names**: All lowercase with `_c` suffix for circumstance variables
4. **Missing Values**: Use NA for missing data (will be converted to 0 for numeric variables)

## Required Variables

### 1. Identifiers (Required)
These variables uniquely identify each case:

| Variable | Type | Description |
|----------|------|-------------|
| `siteid` | Numeric | NVDRS site identifier |
| `incidentyear` | Numeric | Year of incident (e.g., 2019) |
| `incidentid` | Numeric | Unique incident identifier |
| `personid` | Numeric | Person identifier within incident |

The classifier will create a unique `id` by combining: `siteid_incidentyear_incidentid_personid`

### 2. Incident Category (Required)
| Variable | Type | Required Value |
|----------|------|----------------|
| `incidentcategory_c` | Character | "Single suicide" |

**Note**: The classifier only analyzes single suicides. Cases with other values will be filtered out.

### 3. Narrative Text (Required)
| Variable | Type | Description |
|----------|------|-------------|
| `narrativecme` | Character | Coroner/Medical Examiner narrative |
| `narrativele` | Character | Law Enforcement narrative |

Both narratives are combined and analyzed for IPV-related content.

### 4. Demographics (Required)
| Variable | Type | Values | Description |
|----------|------|--------|-------------|
| `sex` | Numeric | 1=Male, 2=Female | Biological sex |
| `ageyears_c` | Numeric | Age in years | Age at death |
| `raceethnicity_c` | Numeric | 1-7 | Race/ethnicity category |
| `maritalstatus` | Numeric | 1-5 | Marital status |
| `educationlevel` | Numeric | 1-5 | Education level |
| `military` | Numeric | 0=No, 1=Yes | Military service |
| `pregnant` | Numeric | 0=No, 1=Yes, 8=N/A, 9=Unknown | Pregnancy status |
| `sexualorientation` | Numeric | 1-3, 9=Unknown | Sexual orientation |
| `transgender` | Numeric | 0=No, 1=Yes | Transgender status |

### 5. Circumstances (Required, all with `_c` suffix)

#### Mental Health Variables
| Variable | Type | Values |
|----------|------|--------|
| `mentalhealthproblem_c` | Numeric | 0=No, 1=Yes |
| `depressedmood_c` | Numeric | 0=No, 1=Yes |
| `mentalhealthtx_c` | Numeric | 0=No, 1=Yes |
| `historysuicidethoughts_c` | Numeric | 0=No, 1=Yes |
| `historysuicideattempts_c` | Numeric | 0=No, 1=Yes |

#### Substance Use Variables
| Variable | Type | Values |
|----------|------|--------|
| `alcoholproblem_c` | Numeric | 0=No, 1=Yes |
| `substanceproblem_c` | Numeric | 0=No, 1=Yes |

#### Relationship and Violence Variables
| Variable | Type | Values |
|----------|------|--------|
| `intimatepartnerproblem_c` | Numeric | 0=No, 1=Yes |
| `familyrelationship_c` | Numeric | 0=No, 1=Yes |
| `interpersonalviolenceperp_c` | Numeric | 0=No, 1=Yes |
| `interpersonalviolencevictim_c` | Numeric | 0=No, 1=Yes |
| `historyofviolence_c` | Numeric | 0=No, 1=Yes |
| `stalking_c` | Numeric | 0=No, 1=Yes |
| `prostitution_c` | Numeric | 0=No, 1=Yes |

#### Life Stressor Variables
| Variable | Type | Values |
|----------|------|--------|
| `jobproblem_c` | Numeric | 0=No, 1=Yes |
| `financialproblem_c` | Numeric | 0=No, 1=Yes |
| `housingstability_c` | Numeric | 0=No, 1=Yes |
| `school_c` | Numeric | 0=No, 1=Yes |
| `recentcriminallegalprob_c` | Numeric | 0=No, 1=Yes |

#### Other Circumstances
| Variable | Type | Values |
|----------|------|--------|
| `crisisinpastweeks_c` | Numeric | 0=No, 1=Yes |
| `physicalhealth_c` | Numeric | 0=No, 1=Yes |
| `catastrophicillness_c` | Numeric | 0=No, 1=Yes |
| `abusivecaregiving_c` | Numeric | 0=No, 1=Yes |
| `disaster_c` | Numeric | 0=No, 1=Yes |
| `suicidedisclosed_c` | Numeric | 0=No, 1=Yes |
| `suicidedisclosedtowhom_c` | Numeric | Various codes |
| `suicide_note_c` | Numeric | 0=No, 1=Yes |

### 6. Weapon Type (Required)
| Variable | Type | Values |
|----------|------|--------|
| `weapon` | Numeric | 1-11 (NVDRS weapon codes) |

## Data Preparation Checklist

Before running the classifier, ensure your data meets these requirements:

- [ ] Data is in `.Rdata` format
- [ ] All variable names are lowercase
- [ ] Circumstance variables have `_c` suffix
- [ ] Only includes single suicide cases
- [ ] Contains all required variables listed above
- [ ] Narrative fields (narrativecme, narrativele) are character type
- [ ] Numeric variables use 0/1 for No/Yes

## Example Data Structure

```r
# Load your NVDRS data
load("data/your_nvdrs_rad_file.Rdata")

# Check structure
str(your_data)

# Should show something like:
# 'data.frame': 1000 obs. of 50 variables:
#  $ siteid                      : num  1 1 1 2 2 ...
#  $ incidentyear                : num  2019 2019 2019 2019 2019 ...
#  $ incidentid                  : num  101 102 103 201 202 ...
#  $ personid                    : num  1 1 1 1 1 ...
#  $ incidentcategory_c          : chr  "Single suicide" "Single suicide" ...
#  $ narrativecme                : chr  "The decedent was found..." ...
#  $ narrativele                 : chr  "Officers responded to..." ...
#  $ sex                         : num  1 2 1 2 1 ...
#  $ ageyears_c                  : num  45 32 67 28 51 ...
#  $ mentalhealthproblem_c       : num  1 0 1 1 0 ...
#  $ intimatepartnerproblem_c    : num  0 1 0 1 0 ...
#  [... more variables ...]
```

## Handling Missing Variables

If your NVDRS extract is missing some required variables:

1. **For binary circumstances**: Create the variable and set all values to 0
2. **For demographics**: Create with appropriate missing value codes (9 for unknown)
3. **For narratives**: Both narrativecme and narrativele must be present (can be empty strings)

Example:
```r
# Add missing binary variable
if(!"stalking_c" %in% names(your_data)) {
  your_data$stalking_c <- 0
}

# Add missing demographic with unknown code
if(!"sexualorientation" %in% names(your_data)) {
  your_data$sexualorientation <- 9
}
```

## Validating Your Data

Run this check before using the classifier:

```r
# Source the validation function
source("R/04_clean_nvdrs_variables.R")

# Get required variables
required_vars <- get_required_nvdrs_variables()

# Check what's missing
missing_vars <- setdiff(required_vars, names(your_data))
if(length(missing_vars) > 0) {
  cat("Missing variables:\n")
  print(missing_vars)
} else {
  cat("All required variables present!\n")
}

# Check incident category
table(your_data$incidentcategory_c)
# Should show only "Single suicide"

# Check narrative availability
narrative_missing <- sum(is.na(your_data$narrativecme) | is.na(your_data$narrativele))
cat("Cases with missing narratives:", narrative_missing, "\n")
```

## Year Considerations

The classifier was trained on 2010-2018 data and includes year-specific effects. For data from 2019 or later:
- The model will still work but uses 2018 parameters for newer years
- Performance should remain comparable for recent years
- Consider the temporal gap when interpreting results for data from 2025+

## Getting NVDRS Data

NVDRS Restricted Access Database (RAD) files require:
1. Approved data use agreement with CDC
2. Completion of required training
3. IRB approval (if applicable)

For more information, visit: https://www.cdc.gov/nvdrs/

## Example Data

To test the classifier without real NVDRS data, use the example data generator:
```r
source("examples/create_example_data.R")
source("examples/run_example.R")
```

This creates synthetic data matching the required format for testing purposes only.