## main.R - Main Script for IPV-Related Suicide Classifier
## Purpose: Orchestrate the complete workflow for detecting IPV-related suicides in NVDRS

# ===== SETUP =====

# Clear environment
rm(list = ls())

# Set working directory (adjust as needed)
# setwd("/path/to/IPV-suicide")

# Source all required scripts
cat("Loading IPV Classifier scripts...\n")
source("R/00_setup.R")          # Load libraries
source("R/utils.R")             # Helper functions
source("R/01_load_data.R")      # Data loading functions
source("R/02_extract_text_features.R")  # Text feature extraction
source("R/03_calculate_concept_scores.R")  # Concept score calculation
source("R/04_clean_nvdrs_variables.R")    # NVDRS variable cleaning
source("R/05_prepare_dataset.R")          # Dataset preparation
source("R/06_apply_classifier.R")         # Model application

# ===== CONFIGURATION =====

# File paths - UPDATE THESE FOR YOUR SYSTEM
config <- list(
  nvdrs_file = "data/RAD_2019_demo_010622.Rdata",  # Your NVDRS RAD file
  concept_file = "models/concept_020122.Rdata",       # Concept term lists
  model_file = "models/IPV_Related_Suicide_rfmodel_2022_01_28.Rdata",  # IPV classifier model
  output_dir = "output",                       # Directory for results
  output_predictions = "output/ipv_predictions.csv",
  output_report = "output/ipv_classifier_report.txt"
)

# Create output directory if it doesn't exist
if(!dir.exists(config$output_dir)) {
  dir.create(config$output_dir)
  cat("Created output directory:", config$output_dir, "\n")
}

# ===== MAIN WORKFLOW =====

run_ipv_classifier <- function(config) {
  
  cat("\n========================================\n")
  cat("IPV-Related Suicide Classifier\n")
  cat("========================================\n")
  cat("Start time:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
  
  # Track timing
  start_time <- Sys.time()
  
  # Step 1: Load all data
  cat("\n[Step 1/7] Loading data...\n")
  data_list <- load_all_data(
    nvdrs_file = config$nvdrs_file,
    concept_file = config$concept_file,
    model_file = config$model_file
  )
  
  # Extract components
  nvdrs_data <- data_list$nvdrs
  concepts <- data_list$concepts
  model <- data_list$model
  
  # Step 2: Extract text features
  cat("\n[Step 2/7] Extracting text features...\n")
  text_features <- extract_text_features_safe(nvdrs_data)
  
  if(is.null(text_features)) {
    stop("Failed to extract text features")
  }
  
  # Step 3: Calculate concept scores
  cat("\n[Step 3/7] Calculating concept scores...\n")
  concept_scores <- calculate_concept_scores(nvdrs_data, config$concept_file)
  
  # Step 4: Clean NVDRS variables
  cat("\n[Step 4/7] Cleaning NVDRS variables...\n")
  nvdrs_clean <- clean_nvdrs_variables(nvdrs_data)
  
  # Step 5: Prepare final dataset
  cat("\n[Step 5/7] Preparing final dataset...\n")
  ready_data <- prepare_final_dataset(nvdrs_clean, text_features, concept_scores)
  
  # Generate summary statistics
  data_summary <- summarize_prepared_data(ready_data)
  
  # Step 6: Apply classifier
  cat("\n[Step 6/7] Applying IPV classifier...\n")
  
  # Validate before prediction
  if(!validate_model_requirements(ready_data, model)) {
    stop("Dataset does not meet model requirements")
  }
  
  # Make predictions
  predictions <- apply_ipv_classifier(ready_data, model)
  
  # Get detailed results
  detailed_predictions <- get_detailed_predictions(predictions, ready_data)
  
  # Analyze patterns
  prediction_analysis <- analyze_prediction_patterns(detailed_predictions)
  
  # Step 7: Export results
  cat("\n[Step 7/7] Exporting results...\n")
  
  # Export predictions
  export_predictions(detailed_predictions, config$output_predictions)
  
  # Generate report
  report_summary <- generate_prediction_report(detailed_predictions, config$output_report)
  
  # Calculate total runtime
  end_time <- Sys.time()
  runtime <- difftime(end_time, start_time, units = "mins")
  
  cat("\n========================================\n")
  cat("IPV Classifier Complete!\n")
  cat("========================================\n")
  cat("Total runtime:", round(runtime, 2), "minutes\n")
  cat("Results saved to:", config$output_dir, "\n\n")
  
  # Return results
  return(list(
    predictions = detailed_predictions,
    summary = data_summary,
    analysis = prediction_analysis,
    report = report_summary,
    runtime = runtime
  ))
}

# ===== EXECUTE WORKFLOW =====

# Run the classifier with error handling
results <- tryCatch({
  run_ipv_classifier(config)
}, error = function(e) {
  cat("\n!!! ERROR OCCURRED !!!\n")
  cat("Error message:", e$message, "\n")
  cat("\nPlease check:\n")
  cat("1. All required files exist in the specified locations\n")
  cat("2. NVDRS data is properly formatted\n")
  cat("3. All required R packages are installed\n")
  return(NULL)
})

# ===== OPTIONAL: INTERACTIVE ANALYSIS =====

if(!is.null(results)) {
  cat("\nClassifier results are now available in the 'results' object.\n")
  cat("You can explore:\n")
  cat("- results$predictions: Detailed predictions for each case\n")
  cat("- results$summary: Summary statistics of the dataset\n")
  cat("- results$analysis: Analysis of prediction patterns\n")
  cat("- results$report: Overall report summary\n")
  
  # Example: View first few predictions
  cat("\nFirst 5 predictions:\n")
  print(head(results$predictions, 5))
}

# Save session information for reproducibility
print_session_info(file.path(config$output_dir, "session_info.txt"))

# ===== END OF MAIN SCRIPT ====="