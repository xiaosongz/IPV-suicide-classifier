# Kafka et al. (2023) Paper Digest: IPV-Related Suicide Classifier

## Overview

**Title**: Detecting intimate partner violence circumstance for suicide: development and validation of a tool using natural language processing and supervised machine learning in the National Violent Death Reporting System

**Authors**: Julie M. Kafka, Mike D. Fliss, Pamela J. Trangenstein, Luz McNaughton Reyes, Brian W. Pence, Kathryn E. Moracco

**Journal**: Injury Prevention, 2023; 29:134-141

**DOI**: 10.1136/ip-2022-044662

**Purpose**: To develop and validate a supervised machine learning (SML) tool using natural language processing (NLP) to detect intimate partner violence (IPV) circumstances in single suicide deaths from the National Violent Death Reporting System (NVDRS).

## Background and Motivation

The NVDRS is a comprehensive surveillance system for violent deaths in the United States, but it has a significant limitation: IPV circumstances are only systematically captured for homicide-suicides (<2% of suicides), but not for single suicides (>98% of suicides). This means that isolated suicides precipitated by IPV are not systematically identified in the database, leading to underestimation of IPV's role in suicide deaths.

Research has shown that both IPV victims and perpetrators report high rates of suicidal thoughts and behaviors. Manual reviews of NVDRS death narratives in Kentucky, North Carolina, and for youth suicides found IPV circumstances in 6.1%-11.4% of suicides. However, comprehensive national assessment would be challenging using manual review. This classifier was developed to provide a scalable solution to this critical gap.

## Methodology

### Data Source

- **Dataset**: NVDRS Restricted Access Database (RAD) from 40 states, Washington DC, and Puerto Rico (2010-2018)
- **Focus**: Single suicide events only (excludes homicide-suicides)
- **Data elements**: Death narratives (CME and LE reports) + structured NVDRS variables

### Training and Validation Data

- **Training dataset**: 8,500 hand-labeled cases
  - 17.9% labeled as IPV=yes (n=1,519)
  - Purposively sampled to maximize IPV-related cases
  - Inter-rater reliability: Kappa 0.71-0.73
  
- **Validation dataset**: 1,500 hand-labeled cases
  - 6.8% labeled as IPV=yes (n=102)
  - Simple random sample for generalizability
  - Used to assess real-world performance

### Development Process

The classifier development followed a systematic approach:

#### 1. Data Preparation
- Filtered for single suicide events only (incident_category_c == "Single suicide")
- Combined coroner/medical examiner (CME) and law enforcement (LE) narratives
- Applied controlled vocabulary to standardize intimate partner references
- Cleaned and preprocessed text data

#### 2. Feature Engineering

The classifier uses 117 input variables across three types:

**A. Text-Based Features** (using textfeatures package):
- Sentiment scores (Syuzhet and VADER)
- Grammatical counts (first/second/third person pronouns, polite words)
- Narrative length in characters

**B. Concept Scores** (26+ IPV-related concepts using dictionary approach):
- **Direct IPV indicators**: abuse (54 terms), physical abuse, sexual abuse, emotional abuse, DVPO
- **Control and threat**: control, spoken threats, suicide threats (manipulative), dangerous person, dangerous weapon
- **Relationship dynamics**: jealousy, deceit, argument, fear, evasion, economic abuse
- **Context indicators**: witness, pictures/text messages, intimate partner location, property damage, revenge
- **Pattern indicators**: pattern of behavior, auxiliary/conditional words, self-harm
- **Other concepts**: intimate partner references, past partners, parents/family, children, justice involvement

**C. NVDRS Structured Variables**:
- Demographics (age, sex, race/ethnicity, marital status, education, military status, pregnancy)
- Incident characteristics (weapon type, location, year)
- Circumstances (mental health, substance use, relationship problems, violence history)
- Toxicology results

#### 3. Concept Scoring Methodology

The classifier uses a Term Frequency-Relative Frequency (TF-RF) weighting approach:

1. **Controlled Vocabulary Application**:
   - Current partners → "iipp" (intimate partner)
   - Former partners → "ex"
   - Removes victim/decedent references ("victim", "decedent", "deceased", "v", "d")
   - Handles reporting party (RP/CP/W) references using 8-character proximity detection

2. **Text Tokenization**:
   - Unigrams (single words)
   - Bigrams (two-word phrases)
   - Trigrams (three-word phrases)
   - Porter stemming (with exceptions for certain terms)
   - Only retains terms appearing in a priori concept lists

3. **TF-RF Calculation** (based on Adji 2016):
   - TF (Term Frequency): How often a term appears in a document
   - RF (Relative Frequency): Pre-calculated weights based on:
     - For IPV-related terms: TF × max(log((A_ij + 1)/(C_ij + 1)), 0)
     - Where A_ij = occurrences in IPV=yes cases, C_ij = occurrences in IPV=no cases
   - Final score: TF × RF for each concept
   - Summary scores: wtsum_ipv_concepts and wtsum_condit_pattern

#### 4. Model Training

- **Algorithm**: Random Forest (selected after testing XGBoost, LASSO, SVM)
- **Training approach**: 
  - 10-fold cross-validation
  - SMOTE (Synthetic Minority Oversampling Technique) for class balancing
  - Iterative feature optimization
- **Validation**: Held-out test set of 1,500 cases
- **Threshold**: 0.5 probability for positive classification

### Key Innovations

1. **Controlled Vocabulary**: Systematically standardizes intimate partner references to improve detection accuracy

2. **Contextual Replacements**: Intelligently identifies when reporting parties (RP/CP/W) refer to intimate partners based on proximity to IP references

3. **Concept-Based Approach**: Groups related terms into meaningful concepts rather than treating individual words in isolation

4. **TF-RF Weighting**: Outperformed TF-IDF, binary representation, and simple frequency approaches

5. **Human Expertise Integration**: Concept scores curated by domain experts were the most important features (according to Gini importance)

## Implementation Verification

The code repository faithfully implements the methodology described:

### Code Structure Alignment

1. **Data Loading** (`01_load_data.R`):
   - Filters for single suicides only
   - Validates required NVDRS variables
   - Loads pre-trained model and concept lists

2. **Text Feature Extraction** (`02_extract_text_features.R`):
   - Uses textfeatures package exactly as described
   - Extracts sentiment scores (Syuzhet, VADER)
   - Counts grammatical features

3. **Concept Score Calculation** (`03_calculate_concept_scores.R`):
   - Implements controlled vocabulary (iipp, ex terms)
   - Handles RP/CP/W replacements using proximity detection
   - Tokenizes into unigrams, bigrams, trigrams
   - Applies TF-RF weighting formula
   - Creates summary scores

4. **NVDRS Variable Cleaning** (`04_clean_nvdrs_variables.R`):
   - Processes all required demographic and circumstance variables
   - Creates year dummy variables
   - Handles missing values appropriately

5. **Model Application** (`06_apply_classifier.R`):
   - Applies Random Forest model
   - Uses 0.5 probability threshold
   - Generates confidence categories

### Key Implementation Details Verified

✓ **Controlled vocabulary** is correctly applied to standardize IP references
✓ **Text cleaning** removes numbers (except 911), handles contractions, removes special characters
✓ **RP/CP/W replacement** logic uses 8-character proximity detection
✓ **Concept terms** are matched using stemming (with exceptions)
✓ **TF-RF calculation** multiplies term frequency by pre-calculated relative frequency weights
✓ **All 26 concepts** are implemented as described
✓ **Summary scores** aggregate IPV-specific and conditional pattern concepts
✓ **Year dummy variables** are created for 2010-2018 even if not in current data

## Results and Performance

### Model Performance Metrics (Validation Dataset)

The final model achieved robust performance on the validation dataset (n=1,500):

- **Sensitivity (Recall)**: 0.70
- **Specificity**: 0.98
- **Precision (PPV)**: 0.72
- **F1 Score**: 0.71
- **Kappa**: 0.69
- **Accuracy**: 0.96
- **Predicted IPV prevalence**: 6.6% (vs. true 6.8%)

### Comparison with Alternative Models

The final model outperformed two comparison approaches:
1. **Model using only NVDRS variables**: Kappa 0.41, F1 0.43
2. **Bag-of-terms approach**: Kappa 0.48, F1 0.45
3. **Final model (all features)**: Kappa 0.69, F1 0.71

### Variable Importance

According to Gini importance analysis:
- **Concept scores** were most important (mean: 111, range: 3-1037)
  - Top concepts: Sum of IPV concepts (1037), physical abuse (577), abuse (433)
- **NVDRS circumstances** moderately important
  - Top variables: Violence perpetration (288), argument (250), suicide intent disclosed to IP (177)
- **Demographics** least important (mean: 12, range: 1-48)

### Error Analysis

**False Positives (n=28)**:
- Most described "domestic incidents" lacking sufficient detail to confirm violence
- Some mentioned family violence (not IPV)
- Two cases were actually human coding errors

**False Negatives (n=31)**:
- Half involved coercive suicide threats (n=15)
- Some used metaphorical language to describe abuse
- Others mentioned abuse and IP context in separate sentences

## Practical Applications

1. **Surveillance Enhancement**: Enables systematic identification of IPV-related suicides in NVDRS
2. **Research**: Facilitates studies on the relationship between IPV and suicide
3. **Public Health**: Improves understanding of IPV's role in suicide for prevention efforts
4. **Policy**: Provides better data for evidence-based policy development
5. **Time Savings**: Could save researchers over 1,450 hours of manual coding per year of suicide data

## Limitations and Considerations

### Data Limitations

1. **Multiple layers of underreporting**:
   - IPV is underreported in general population
   - Stigma may prevent disclosure during death investigations
   - CME/LE don't routinely probe for IPV in suicide investigations
   - NVDRS abstractors not instructed to document IPV for suicides

2. **Temporal constraints**: Death narratives typically report IPV only if violent incident occurred within 2 weeks of suicide

3. **Ambiguous language**: Vague terms like "domestic incident" without clarifying details limited model sensitivity

### Technical Limitations

1. **Training Period**: Model trained on 2010-2018 data; may need updates for newer patterns
2. **Single Suicides Only**: Not designed for homicide-suicides (use existing NVDRS IPV variable)
3. **English Language**: Designed for English narratives only
4. **Dictionary approach**: May miss new IPV-related language not in concept lists
5. **Kappa ceiling**: Human inter-rater reliability (0.71-0.73) sets performance ceiling

## Recommendations for Future Improvements

The authors suggest several improvements to enhance IPV detection:

1. **Data Collection**: 
   - Amend NVDRS coding guidelines to require systematic assessment of IPV for suicides
   - Update death investigation protocols to encourage documentation of IPV details
   - Train CME/LE to clearly document parties involved and specific violent behaviors

2. **Technical Enhancements**:
   - Consider neural network approaches for handling complex linguistic patterns
   - Update concept lists periodically to capture evolving language
   - Develop methods to better detect coercive suicide threats

## Conclusion

The Kafka et al. (2023) IPV-Related Suicide Classifier represents a significant advancement in suicide surveillance methodology. By combining natural language processing, domain expertise, and machine learning, it addresses a critical gap in the NVDRS system. The tool achieved substantial performance (Kappa 0.69, F1 0.71) comparable to human inter-rater reliability, demonstrating its readiness for deployment.

The implementation in this repository accurately reflects the sophisticated methodology described in the paper, including:
- Exact replication of the controlled vocabulary system
- Proper implementation of TF-RF weighting
- All 26+ concept categories with appropriate term lists
- Correct handling of NVDRS variables and text preprocessing

The classifier's innovative approach—particularly the human-curated concept scores, controlled vocabulary, and TF-RF weighting—demonstrates how domain expertise can be effectively integrated with machine learning to solve real-world public health challenges. This tool enables researchers to comprehensively study IPV-related suicide for the first time at a national scale, potentially informing more holistic prevention efforts targeting both IPV and suicide.