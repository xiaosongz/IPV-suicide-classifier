# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains the IPV-Related Suicide Classifier, a machine learning tool developed to detect Intimate Partner Violence (IPV) circumstances in suicide data from the National Violent Death Reporting System (NVDRS). The tool was created as part of Julie M Kafka's 2022 dissertation and is documented in a peer-reviewed publication in Injury Prevention journal.

## Key Components

### Model Files (Required for Running the Classifier)
- `models/IPV_Related_Suicide_rfmodel_2022_01_28.Rdata` - Pre-trained Random Forest model
- `models/concept_020122.Rdata` - Concept term lists for feature extraction

### Documentation
- `docs/Dissertation_Markdown_2023_03_22.html` - Comprehensive R workflow demonstration
- `docs/Dissertation_Markdown_2023_03_22.md` - Markdown version of the workflow
- `docs/CLAUDE.md` - This file, guidance for Claude Code
- Published paper: http://doi.org/10.1136/ip-2022-044662

### Code Implementation
- `R/` folder - Modular R scripts implementing the complete workflow:
  - `00_setup.R` - Package loading
  - `01_load_data.R` - Data loading functions
  - `02_extract_text_features.R` - Text feature extraction
  - `03_calculate_concept_scores.R` - Concept score calculation
  - `04_clean_nvdrs_variables.R` - NVDRS variable preparation
  - `05_prepare_dataset.R` - Dataset combination
  - `06_apply_classifier.R` - Model application
  - `main.R` - Complete workflow orchestration
  - `utils.R` - Helper functions

## R Dependencies

The following R packages are required:
```r
# Data manipulation
library(dplyr)
library(tidyverse)
library(stringr)

# Text processing
library(tidytext)
library(textfeatures)
library(stopwords)
library(SnowballC)
library(textstem)

# Modeling
library(tidymodels)

# Additional utilities
library(stringi)  # For string width calculation
library(purrr)    # For functional programming
```

## Common Commands

### Quick Start - Run Complete Workflow
```r
# Set working directory to repository root
setwd("/path/to/IPV-suicide")

# Run the complete workflow (requires NVDRS data)
source("R/main.R")

# Or test with example data (no NVDRS data required)
source("examples/run_example.R")
```

### Step-by-Step Execution
```r
# 1. Setup environment
source("R/00_setup.R")

# 2. Load all data
source("R/01_load_data.R")
data_list <- load_all_data(
  nvdrs_file = "data/your_nvdrs_file.Rdata",
  concept_file = "models/concept_020122.Rdata",
  model_file = "models/IPV_Related_Suicide_rfmodel_2022_01_28.Rdata"
)

# 3. Process the data through the pipeline
source("R/02_extract_text_features.R")
source("R/03_calculate_concept_scores.R")
source("R/04_clean_nvdrs_variables.R")
source("R/05_prepare_dataset.R")
source("R/06_apply_classifier.R")

# Apply the classifier
predictions <- apply_ipv_classifier(prepared_data, model)
```

## Architecture and Workflow

### Data Processing Pipeline
1. **Input**: NVDRS RAD file containing suicide death records
2. **Filtering**: Extract single suicide events only (incidentcategory_c == "Single suicide")
3. **Feature Engineering**:
   - **NVDRS Variables**: Demographics, circumstances, weapon type, mental health indicators
   - **Text Features**: Sentiment scores (Syuzhet, VADER) and grammatical patterns from narratives
   - **Concept Scores**: TF-RF weighted scores for 26 IPV-related concepts
4. **Prediction**: Random Forest model produces probability of IPV-related suicide

### Key Processing Steps

#### Text Processing
- Combine CME and LE narratives into single text field
- Apply controlled vocabulary (standardize intimate partner terms to "iipp", ex-partner terms to "ex")
- Handle reporting party references (CP/W/RP) that may refer to intimate partners
- Remove numbers (except 911), special characters, and normalize text
- Extract features using `textfeatures` package

#### Concept Score Calculation
- Tokenize text into unigrams, bigrams, and trigrams
- Apply stemming (with exceptions for certain terms)
- Match tokens against predefined concept terms
- Calculate TF-RF (Term Frequency × Relative Frequency) weights
- Aggregate into concept-level scores
- Create summary scores: wtsum_ipv_concepts and wtsum_condit_pattern

#### Variable Preparation
- Clean and categorize demographic variables
- Create binary indicators for circumstances
- Handle year dummy variables (2010-2018, even if not in current data)
- Calculate narrative length
- Set missing numeric values to 0

### Required NVDRS Variables

The classifier requires specific NVDRS variables with exact naming (_c suffix for circumstances):
- Demographics: sex, ageyears_c, raceethnicity_c, maritalstatus, educationlevel
- Circumstances: alcoholproblem_c, mentalhealthproblem_c, intimatepartnerproblem_c, etc.
- Narratives: narrativecme, narrativele
- Must filter for: incidentcategory_c == "Single suicide"

## Important Notes

- This is a research tool for analyzing existing suicide data, not for real-time prediction
- The model was trained on 2010-2018 data; year dummy variables must be included even for newer data
- All NVDRS variable names must be lowercase
- Missing concept scores (when keywords aren't found) are automatically set to 0
- The classifier uses a 0.5 probability threshold by default
- Process time: ~5-10 minutes for 30,000 cases
- NVDRS data requires special access; example data is provided for testing
- The concept_020122.Rdata file contains term lists with relative frequencies, not the notes to process

## Concept Categories

The classifier identifies 26 concepts grouped into:
- **IPV-specific**: harm_other, harm_emot, harm_sex, harm_phys, fear, evade, economic, jealousy, deceit, control, revenge, witness, pics, ip_place, property, danger_person, danger_weapon, stalk, threat, threat_suicide, abuse, dvpo
- **Conditional patterns**: aux_condit, pattern, self_harm, argue

## Output Format

Predictions include:
- `pred_class`: "yes" (IPV-related) or "no" 
- `.pred_yes`: Probability of IPV-related suicide (0-1)
- `.pred_no`: Probability of non-IPV suicide (0-1)
- Original case ID for matching back to source data