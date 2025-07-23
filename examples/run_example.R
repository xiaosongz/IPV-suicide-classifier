## run_example.R - Example script demonstrating IPV classifier usage
## IPV-Related Suicide Classifier
## Purpose: Show users how to run the classifier with example data

# Clear environment
rm(list = ls())

# Set working directory to repository root
# setwd("/path/to/IPV-suicide")

cat("========================================\n")
cat("IPV Classifier Example\n")
cat("========================================\n\n")

# First, create the example data if it doesn't exist
if(!file.exists("examples/example_nvdrs_data.Rdata")) {
  cat("Creating example data...\n")
  source("examples/create_example_data.R")
  cat("\n")
}

# Source the main script with modified config for example
cat("Loading IPV Classifier...\n\n")

# Load all required scripts
source("R/00_setup.R")
source("R/utils.R")
source("R/01_load_data.R")
source("R/02_extract_text_features.R")
source("R/03_calculate_concept_scores.R")
source("R/04_clean_nvdrs_variables.R")
source("R/05_prepare_dataset.R")
source("R/06_apply_classifier.R")

# Configuration for example
config <- list(
  nvdrs_file = "examples/example_nvdrs_data.Rdata",
  concept_file = "models/concept_020122.Rdata",
  model_file = "models/IPV_Related_Suicide_rfmodel_2022_01_28.Rdata",
  output_dir = "examples/output",
  output_predictions = "examples/output/example_ipv_predictions.csv",
  output_report = "examples/output/example_ipv_report.txt"
)

# Create output directory
if(!dir.exists(config$output_dir)) {
  dir.create(config$output_dir, recursive = TRUE)
}

# Run the classifier
cat("\n========================================\n")
cat("Running IPV Classifier on Example Data\n")
cat("========================================\n\n")

tryCatch({
  
  # Step 1: Load data
  cat("[Step 1/6] Loading example data...\n")
  data_list <- load_all_data(
    nvdrs_file = config$nvdrs_file,
    concept_file = config$concept_file,
    model_file = config$model_file
  )
  
  nvdrs_data <- data_list$nvdrs
  cat("  - Loaded", nrow(nvdrs_data), "example cases\n")
  
  # Step 2: Extract text features
  cat("\n[Step 2/6] Extracting text features from narratives...\n")
  text_features <- extract_text_features_safe(nvdrs_data)
  cat("  - Extracted", ncol(text_features) - 1, "text features\n")
  
  # Step 3: Calculate concept scores
  cat("\n[Step 3/6] Calculating concept scores...\n")
  concept_scores <- calculate_concept_scores(nvdrs_data, config$concept_file)
  cat("  - Calculated scores for", ncol(concept_scores) - 3, "concepts\n")
  
  # Step 4: Clean NVDRS variables
  cat("\n[Step 4/6] Preparing NVDRS variables...\n")
  nvdrs_clean <- clean_nvdrs_variables(nvdrs_data)
  cat("  - Prepared", ncol(nvdrs_clean) - ncol(nvdrs_data), "additional variables\n")
  
  # Step 5: Prepare final dataset
  cat("\n[Step 5/6] Combining all features...\n")
  ready_data <- prepare_final_dataset(nvdrs_clean, text_features, concept_scores)
  cat("  - Final dataset has", ncol(ready_data), "features\n")
  
  # Step 6: Apply classifier
  cat("\n[Step 6/6] Applying IPV classifier...\n")
  
  # Validate model requirements
  if(!validate_model_requirements(ready_data, data_list$model)) {
    stop("Dataset does not meet model requirements")
  }
  
  # Make predictions
  predictions <- apply_ipv_classifier(ready_data, data_list$model)
  detailed_predictions <- get_detailed_predictions(predictions, ready_data)
  
  # Export results
  export_predictions(detailed_predictions, config$output_predictions)
  report_summary <- generate_prediction_report(detailed_predictions, config$output_report)
  
  cat("\n========================================\n")
  cat("Example Complete!\n")
  cat("========================================\n\n")
  
  # Display summary results
  cat("Summary of Predictions:\n")
  cat("----------------------\n")
  pred_summary <- detailed_predictions %>%
    group_by(pred_class) %>%
    summarise(
      count = n(),
      avg_probability = mean(.pred_yes),
      .groups = "drop"
    )
  print(pred_summary)
  
  cat("\nConfidence Distribution:\n")
  cat("----------------------\n")
  conf_summary <- detailed_predictions %>%
    group_by(confidence_category) %>%
    summarise(
      count = n(),
      avg_probability = mean(.pred_yes),
      .groups = "drop"
    ) %>%
    arrange(desc(avg_probability))
  print(conf_summary)
  
  cat("\nTop 5 High-Risk Cases:\n")
  cat("----------------------\n")
  top_cases <- detailed_predictions %>%
    arrange(desc(.pred_yes)) %>%
    select(id, pred_class, .pred_yes, confidence_category) %>%
    head(5)
  print(top_cases)
  
  cat("\nResults saved to:\n")
  cat("  - Predictions:", config$output_predictions, "\n")
  cat("  - Report:", config$output_report, "\n")
  
  cat("\nNOTE: This is synthetic example data for demonstration purposes.\n")
  cat("      Real NVDRS data is required for actual analyses.\n")
  
}, error = function(e) {
  cat("\n!!! ERROR OCCURRED !!!\n")
  cat("Error message:", e$message, "\n")
  cat("\nThis is likely due to missing model files or package issues.\n")
  cat("Please ensure all required files are present in the models/ directory.\n")
})