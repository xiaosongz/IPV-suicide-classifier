## create_example_data.R - Generate synthetic NVDRS-like data for testing
## IPV-Related Suicide Classifier
## Purpose: Create example dataset that demonstrates expected data format

# Load required libraries
library(dplyr)
library(tidyr)

# Set seed for reproducibility
set.seed(42)

# Function to create synthetic NVDRS data
create_synthetic_nvdrs_data <- function(n = 100) {
  
  # Generate base dataset
  data <- tibble(
    # Identifiers
    siteid = sample(1:50, n, replace = TRUE),
    incidentyear = sample(2015:2018, n, replace = TRUE),
    incidentid = seq_len(n),
    personid = seq_len(n),
    id = paste0(siteid, "_", incidentyear, "_", incidentid, "_", personid),
    
    # Must be single suicide for this classifier
    incidentcategory_c = "Single suicide",
    
    # Demographics
    sex = sample(c(1, 2), n, replace = TRUE, prob = c(0.75, 0.25)),
    ageyears_c = sample(18:85, n, replace = TRUE),
    raceethnicity_c = sample(1:5, n, replace = TRUE),
    maritalstatus = sample(1:5, n, replace = TRUE),
    educationlevel = sample(1:4, n, replace = TRUE),
    military = sample(0:1, n, replace = TRUE, prob = c(0.9, 0.1)),
    pregnant = ifelse(sex == 2, sample(0:1, n, replace = TRUE, prob = c(0.95, 0.05)), 0),
    sexualorientation = sample(c(1, 2, 3, 9), n, replace = TRUE, prob = c(0.85, 0.05, 0.05, 0.05)),
    transgender = sample(0:1, n, replace = TRUE, prob = c(0.99, 0.01)),
    
    # Weapon type
    weapon = sample(1:11, n, replace = TRUE, prob = c(0.5, 0.25, 0.1, rep(0.015, 8))),
    
    # Generate IPV probability for creating realistic patterns
    ipv_true = sample(0:1, n, replace = TRUE, prob = c(0.7, 0.3))
  )
  
  # Add circumstance variables based on IPV status
  circumstances <- data %>%
    mutate(
      # Mental health variables
      mentalhealthproblem_c = sample(0:1, n, replace = TRUE, prob = c(0.4, 0.6)),
      depressedmood_c = sample(0:1, n, replace = TRUE, prob = c(0.5, 0.5)),
      mentalhealthtx_c = sample(0:1, n, replace = TRUE, prob = c(0.6, 0.4)),
      historysuicidethoughts_c = sample(0:1, n, replace = TRUE, prob = c(0.7, 0.3)),
      historysuicideattempts_c = sample(0:1, n, replace = TRUE, prob = c(0.8, 0.2)),
      
      # Substance use
      alcoholproblem_c = sample(0:1, n, replace = TRUE, prob = c(0.7, 0.3)),
      substanceproblem_c = sample(0:1, n, replace = TRUE, prob = c(0.8, 0.2)),
      
      # IPV-related circumstances (more likely if ipv_true)
      intimatepartnerproblem_c = ifelse(ipv_true == 1, 
                                        sample(0:1, n, replace = TRUE, prob = c(0.2, 0.8)),
                                        sample(0:1, n, replace = TRUE, prob = c(0.7, 0.3))),
      familyrelationship_c = sample(0:1, n, replace = TRUE, prob = c(0.7, 0.3)),
      interpersonalviolenceperp_c = ifelse(ipv_true == 1,
                                          sample(0:1, n, replace = TRUE, prob = c(0.6, 0.4)),
                                          sample(0:1, n, replace = TRUE, prob = c(0.95, 0.05))),
      interpersonalviolencevictim_c = ifelse(ipv_true == 1,
                                            sample(0:1, n, replace = TRUE, prob = c(0.4, 0.6)),
                                            sample(0:1, n, replace = TRUE, prob = c(0.9, 0.1))),
      historyofviolence_c = ifelse(ipv_true == 1,
                                  sample(0:1, n, replace = TRUE, prob = c(0.5, 0.5)),
                                  sample(0:1, n, replace = TRUE, prob = c(0.9, 0.1))),
      
      # Other life stressors
      jobproblem_c = sample(0:1, n, replace = TRUE, prob = c(0.8, 0.2)),
      financialproblem_c = sample(0:1, n, replace = TRUE, prob = c(0.7, 0.3)),
      housingstability_c = sample(0:1, n, replace = TRUE, prob = c(0.85, 0.15)),
      school_c = sample(0:1, n, replace = TRUE, prob = c(0.95, 0.05)),
      recentcriminallegalprob_c = sample(0:1, n, replace = TRUE, prob = c(0.9, 0.1)),
      
      # Additional IPV indicators
      stalking_c = ifelse(ipv_true == 1,
                         sample(0:1, n, replace = TRUE, prob = c(0.7, 0.3)),
                         sample(0:1, n, replace = TRUE, prob = c(0.98, 0.02))),
      prostitution_c = sample(0:1, n, replace = TRUE, prob = c(0.99, 0.01)),
      
      # Other circumstances
      crisisinpastweeks_c = sample(0:1, n, replace = TRUE, prob = c(0.6, 0.4)),
      physicalhealth_c = sample(0:1, n, replace = TRUE, prob = c(0.8, 0.2)),
      catastrophicillness_c = sample(0:1, n, replace = TRUE, prob = c(0.95, 0.05)),
      abusivecaregiving_c = sample(0:1, n, replace = TRUE, prob = c(0.99, 0.01)),
      disaster_c = sample(0:1, n, replace = TRUE, prob = c(0.99, 0.01)),
      
      # Disclosure
      suicidedisclosed_c = sample(0:1, n, replace = TRUE, prob = c(0.7, 0.3)),
      suicidedisclosedtowhom_c = sample(0:1, n, replace = TRUE, prob = c(0.8, 0.2)),
      suicide_note_c = sample(0:1, n, replace = TRUE, prob = c(0.7, 0.3))
    )
  
  # Generate example narratives
  narratives <- circumstances %>%
    mutate(
      narrativecme = case_when(
        ipv_true == 1 & intimatepartnerproblem_c == 1 ~ sample(c(
          "The decedent was found by her boyfriend after an argument about their relationship. She had been experiencing emotional abuse and threats from her partner for several months. Friends reported she was afraid of him.",
          "The victim had recently separated from her husband due to domestic violence. She had filed for a protective order last month. Her ex-husband had been stalking her and making threats.",
          "The deceased had been in an abusive relationship with her girlfriend for two years. She had attempted to leave multiple times but her partner would threaten suicide. There was a history of physical violence.",
          "The decedent's wife reported finding him after a fight about finances. He had been controlling about money and had isolated him from family. There were previous reports of emotional abuse."
        ), 1),
        ipv_true == 1 ~ sample(c(
          "The victim was in a tumultuous relationship with frequent arguments. Partner reported jealousy issues and controlling behavior. Friends noted signs of emotional distress related to the relationship.",
          "The deceased had been having relationship problems with her boyfriend. There were reports of verbal arguments and one instance of property damage during a fight."
        ), 1),
        mentalhealthproblem_c == 1 ~ sample(c(
          "The decedent had a long history of depression and was receiving treatment. Family reported recent medication changes and increased isolation.",
          "The victim had been diagnosed with bipolar disorder and had stopped taking medication. Recent job loss exacerbated mental health symptoms."
        ), 1),
        TRUE ~ sample(c(
          "The deceased was found by a family member. Had been experiencing financial difficulties and recent health problems.",
          "The victim left a note mentioning feeling like a burden to family. Had chronic pain issues and limited mobility.",
          "The decedent had been struggling with substance abuse and had lost job recently. Family was attempting to help with treatment."
        ), 1)
      ),
      
      narrativele = case_when(
        ipv_true == 1 & interpersonalviolenceperp_c == 1 ~ sample(c(
          "Responding officers noted previous domestic violence calls to the residence. The boyfriend was present and stated they had been arguing earlier. Neighbors confirmed hearing loud arguments frequently.",
          "Investigation revealed the victim had called 911 two weeks prior reporting threats from ex-partner. Protective order was in place. Ex-partner had alibi for time of death.",
          "Officers found evidence of struggle in the home. Partner admitted to physical altercation earlier that day. History of mutual violence reported by family."
        ), 1),
        ipv_true == 1 ~ sample(c(
          "Partner was first to call 911. Reported finding victim after returning from work. No signs of forced entry or struggle at scene.",
          "Ex-girlfriend discovered body and called police. They had broken up one month prior due to relationship issues."
        ), 1),
        TRUE ~ sample(c(
          "No signs of foul play. Weapon was registered to victim. Note was found at scene referencing personal struggles.",
          "Scene investigation revealed no suspicious circumstances. Family confirmed victim had been depressed recently.",
          "Officers responded to welfare check requested by employer. Victim had not shown up for work in two days."
        ), 1)
      )
    ) %>%
    select(-ipv_true)  # Remove the synthetic IPV indicator
  
  return(narratives)
}

# Create example dataset
cat("Creating synthetic NVDRS example data...\n")
example_nvdrs <- create_synthetic_nvdrs_data(n = 50)

# Save as RData file
save(example_nvdrs, file = "examples/example_nvdrs_data.Rdata")
cat("Example data saved to: examples/example_nvdrs_data.Rdata\n")

# Also save as CSV for inspection
write.csv(example_nvdrs, "examples/example_nvdrs_data.csv", row.names = FALSE)
cat("CSV version saved to: examples/example_nvdrs_data.csv\n")

# Print summary
cat("\nExample dataset created with", nrow(example_nvdrs), "synthetic cases\n")
cat("Variables included:\n")
cat(paste("  -", names(example_nvdrs)), sep = "\n")