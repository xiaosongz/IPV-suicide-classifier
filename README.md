# IPV-Related Suicide Classifier

A machine learning tool to detect intimate partner violence (IPV) circumstances in suicide data from the National Violent Death Reporting System (NVDRS).

## Acknowledgments

This repository is based on the original work by Julie M. Kafka, available at https://github.com/jkafka/IPV-suicide. The enhanced version presented here reorganizes the code structure, adds modular R scripts, improves documentation, and provides a streamlined workflow while maintaining the core methodology and model developed by Kafka.

## Original Work Citation

This classifier was developed as part of Julie M Kafka's 2022 dissertation and is documented in a peer-reviewed publication:

**Citation**: Kafka JM, et al. "Development and validation of a machine learning classifier to identify intimate partner violence-related suicide in the National Violent Death Reporting System." *Injury Prevention* 2023. http://doi.org/10.1136/ip-2022-044662

## Table of Contents
- [Overview](#overview)
- [Quick Start](#quick-start)
- [Repository Structure](#repository-structure)
- [Installation](#installation)
- [Usage](#usage)
- [Data Flow](#data-flow)
- [Understanding the Methodology](#understanding-the-methodology)
- [Output Interpretation](#output-interpretation)
- [Troubleshooting](#troubleshooting)
- [Additional Resources](#additional-resources)

## Overview

The IPV classifier is a Random Forest machine learning model that identifies IPV-related suicides by analyzing:
- **Death narratives** from coroners/medical examiners and law enforcement
- **Structured NVDRS variables** (demographics, circumstances, mental health)
- **Concept-based text features** derived from domain expertise

The classifier was trained on labeled NVDRS data from 2010-2018 and achieves high accuracy in detecting IPV-related circumstances in suicide deaths.

## Quick Start

### Prerequisites
- R (version 4.0 or higher)
- Required R packages (see [Installation](#installation))
- NVDRS RAD file with required variables
- Model files from this repository

### Basic Usage

```r
# Set working directory to repository root
setwd("/path/to/IPV-suicide")

# Run the complete pipeline
source("R/main.R")
```

## Repository Structure

```
IPV-suicide/
├── R/                      # R source code
│   ├── 00_setup.R         # Package loading
│   ├── 01_load_data.R     # Data loading functions
│   ├── 02_extract_text_features.R    # Text feature extraction
│   ├── 03_calculate_concept_scores.R  # Concept score calculation
│   ├── 04_clean_nvdrs_variables.R    # NVDRS variable preparation
│   ├── 05_prepare_dataset.R          # Dataset combination
│   ├── 06_apply_classifier.R         # Model application
│   ├── main.R             # Main workflow script
│   └── utils.R            # Helper functions
├── models/                 # Pre-trained models and data
│   ├── IPV_Related_Suicide_rfmodel_2022_01_28.Rdata
│   └── concept_020122.Rdata
├── docs/                   # Documentation
│   ├── Dissertation_Markdown_2023_03_22.html
│   ├── Dissertation_Markdown_2023_03_22.md
│   └── CLAUDE.md
├── data/                   # Input data (user-provided, gitignored)
├── output/                 # Results output (gitignored)
├── examples/               # Example scripts and data
└── README.md              # This file
```

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/[username]/IPV-suicide.git
cd IPV-suicide
```

### 2. Install Required R Packages

```r
# Install all required packages
install.packages(c(
  "tidyverse",      # Includes dplyr, tidyr, stringr, purrr
  "tidytext",       # Text tokenization
  "textfeatures",   # Sentiment and grammar features
  "stopwords",      # Stop word lists
  "SnowballC",      # Porter stemming
  "textstem",       # Lemmatization
  "tidymodels",     # Model application
  "stringi"         # String utilities
))
```

### 3. Prepare Your Data

Place your NVDRS RAD file in the `data/` directory. The file must contain [required variables](#required-nvdrs-variables).

**Note**: NVDRS data requires special access permissions. If you don't have NVDRS data yet, you can test the classifier with synthetic example data by running:
```r
source("examples/run_example.R")
```

For detailed data format requirements, see `docs/NVDRS_Data_Format.md`.

## Usage

### Option 1: Automated Full Pipeline

Edit the configuration in `R/main.R`:

```r
config <- list(
  nvdrs_file = "data/your_nvdrs_data.Rdata",
  concept_file = "models/concept_020122.Rdata",
  model_file = "models/IPV_Related_Suicide_rfmodel_2022_01_28.Rdata",
  output_dir = "output"
)
```

Then run:
```r
source("R/main.R")
```

### Option 2: Step-by-Step Execution

```r
# Load all functions
source("R/00_setup.R")
source("R/utils.R")
for(script in list.files("R", pattern = "^[0-9]{2}_.*\\.R$", full.names = TRUE)) {
  source(script)
}

# Execute pipeline
data_list <- load_all_data(
  nvdrs_file = "data/your_nvdrs.Rdata",
  concept_file = "models/concept_020122.Rdata",
  model_file = "models/IPV_Related_Suicide_rfmodel_2022_01_28.Rdata"
)

nvdrs_data <- data_list$nvdrs
text_features <- extract_text_features(nvdrs_data)
concept_scores <- calculate_concept_scores(nvdrs_data, "models/concept_020122.Rdata")
nvdrs_clean <- clean_nvdrs_variables(nvdrs_data)
ready_data <- prepare_final_dataset(nvdrs_clean, text_features, concept_scores)
predictions <- apply_ipv_classifier(ready_data, data_list$model)
```

## Data Flow

```
┌─────────────────────┐
│  NVDRS RAD File     │
│  (.Rdata format)    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 1. Filter Single    │ ──► Only analyzes isolated suicides
│    Suicides         │     (excludes homicide-suicides)
└──────────┬──────────┘
           │
     ┌─────┴─────┐
     │           │
     ▼           ▼
┌──────────┐  ┌────────────────┐
│ 2. Text  │  │ 4. Clean NVDRS │
│ Features │  │    Variables   │
└────┬─────┘  └───────┬────────┘
     │                │
     ▼                │
┌──────────────┐      │
│ 3. Concept   │      │
│    Scores    │      │
└──────┬───────┘      │
       │              │
       └──────┬───────┘
              ▼
    ┌─────────────────┐
    │ 5. Combine All  │
    │    Features     │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │ 6. Apply Random │ ──► IPV Classification
    │  Forest Model   │     (Yes/No + Probability)
    └─────────────────┘
```

### Required NVDRS Variables

Your NVDRS RAD file must contain these variables with exact names (case-sensitive after conversion to lowercase):

**Essential Variables:**
- `incidentcategory_c` - Must equal "Single suicide"
- `narrativecme` - Coroner/Medical Examiner narrative
- `narrativele` - Law Enforcement narrative
- `siteid`, `incidentyear`, `incidentid`, `personid`

**Demographic Variables:**
- `sex`, `ageyears_c`, `raceethnicity_c`, `maritalstatus`, `educationlevel`
- `military`, `pregnant`, `sexualorientation`, `transgender`

**Circumstance Variables** (all with `_c` suffix):
- Mental health: `mentalhealthproblem_c`, `depressedmood_c`, etc.
- Relationships: `intimatepartnerproblem_c`, `familyrelationship_c`, etc.
- Violence: `interpersonalviolenceperp_c`, `stalking_c`, etc.
- Life stressors: `jobproblem_c`, `financialproblem_c`, etc.

See `R/04_clean_nvdrs_variables.R` for the complete list.

## Understanding the Methodology

### Text Processing Pipeline

1. **Controlled Vocabulary**: Standardizes intimate partner references
   - Current partners → "iipp" (boyfriend, girlfriend, wife, husband, etc.)
   - Former partners → "ex" (divorced, separated, estranged, etc.)

2. **Concept Scoring**: Identifies 26 IPV-related concepts in narratives
   - Direct harm indicators (physical, emotional, sexual)
   - Control and threat behaviors
   - Relationship dynamics
   - Context indicators

3. **TF-RF Weighting**: Calculates Term Frequency × Relative Frequency scores

### The 26 IPV-Related Concepts

**Direct IPV Indicators:**
- `harm_phys`, `harm_emot`, `harm_sex`, `harm_other`
- `abuse`, `dvpo` (protective orders)

**Control and Threat:**
- `control`, `threat`, `threat_suicide`
- `danger_person`, `danger_weapon`, `stalk`

**Relationship Dynamics:**
- `jeal` (jealousy), `deceit`, `argue`
- `fear`, `evade`, `economic`

**Context Indicators:**
- `witness`, `pics`, `ip_place`
- `property`, `rev` (revenge)

**Patterns:**
- `pattern`, `aux_condit`, `self_harm`

## Output Interpretation

### Prediction Files

The classifier generates three output files in the `output/` directory:

1. **ipv_predictions.csv** - Main results file containing:
   - `id`: Unique case identifier
   - `pred_class`: IPV classification ("yes" or "no")
   - `.pred_yes`: Probability of IPV-related suicide (0-1)
   - `confidence_category`: "High" (≥0.8), "Moderate" (≥0.6), or "Low" (<0.6)
   - Demographic information

2. **ipv_classifier_report.txt** - Summary statistics

3. **session_info.txt** - R session information for reproducibility

### Interpreting Probabilities

- **High confidence IPV (≥0.8)**: Strong evidence of IPV involvement
- **Moderate confidence (0.6-0.8)**: Likely IPV-related, review recommended
- **Borderline cases (0.4-0.6)**: Requires careful review
- **Low IPV probability (<0.4)**: Unlikely to be IPV-related

## Troubleshooting

### Common Issues

#### "Missing required columns"
```r
# Check what's missing
source("R/04_clean_nvdrs_variables.R")
required <- get_required_nvdrs_variables()
missing <- setdiff(required, names(your_data))
print(missing)
```

#### Memory errors with large datasets
```r
# Process by year
nvdrs_2019 <- nvdrs_data %>% filter(incidentyear == 2019)
```

#### Validation checks
```r
# Verify data structure
table(nvdrs_data$incidentcategory_c)  # Should show "Single suicide"

# Check narrative availability
sum(is.na(nvdrs_data$narrativecme) | is.na(nvdrs_data$narrativele))
```

### Performance Notes

Processing time estimates:
- 1,000 cases: ~30 seconds
- 10,000 cases: ~3-5 minutes
- 30,000 cases: ~8-12 minutes

Memory requirements:
- Base: 4GB RAM
- Large datasets (>50k): 8-16GB RAM

## Additional Resources

### Documentation

- **Full Demonstration**: View the complete workflow in `docs/Dissertation_Markdown_2023_03_22.html`
- **Published Paper**: http://doi.org/10.1136/ip-2022-044662
- **Author's Website**: https://jkafka.github.io/ (click "IPV-related suicide" tab)

### Model Files

The following files are required and included in this repository:
- `models/concept_020122.Rdata` - Concept term lists with relative frequencies
- `models/IPV_Related_Suicide_rfmodel_2022_01_28.Rdata` - Pre-trained Random Forest model

### Advanced Usage

For custom probability thresholds:
```r
predictions <- apply_ipv_classifier(data, model, probability_threshold = 0.7)
```

For batch processing multiple files:
```r
files <- list.files("data", pattern = "NVDRS.*\\.Rdata", full.names = TRUE)
results <- lapply(files, function(f) {
  data <- load_nvdrs_data(f)
  # ... process each file
})
```

## Support

For questions or issues:
1. Check this README and the documentation in `docs/`
2. Review the published paper for methodology details
3. Submit issues to the GitHub repository

## License

This enhanced version maintains the same license as the original work. Please refer to the original repository (https://github.com/jkafka/IPV-suicide) for license details. When using this classifier in your research, please cite the published paper.

## Credits and Acknowledgments

### Original Development
This classifier was originally developed by Julie M. Kafka as part of her 2022 dissertation. The original repository is available at https://github.com/jkafka/IPV-suicide.

### This Enhanced Version
This repository provides an enhanced implementation with:
- Reorganized code structure following R best practices
- Modular R scripts for easier understanding and maintenance
- Improved documentation and usage instructions
- Streamlined workflow automation

The core methodology, model, and scientific approach remain unchanged from Kafka's original work.

### Data Source
The classifier was developed using data from the National Violent Death Reporting System (NVDRS), which is maintained by the Centers for Disease Control and Prevention (CDC).