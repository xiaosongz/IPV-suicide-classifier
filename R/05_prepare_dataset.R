## 05_prepare_dataset.R - Prepare Final Dataset for IPV Classifier
## IPV-Related Suicide Classifier
## Purpose: Combine all features and prepare the final dataset for classification

#' Prepare final dataset by combining all features
#' @param nvdrs_clean Cleaned NVDRS variables dataframe
#' @param text_features Text features dataframe from textfeatures package
#' @param concept_scores Concept scores dataframe
#' @return Combined dataframe ready for IPV classifier
prepare_final_dataset <- function(nvdrs_clean, text_features, concept_scores) {
  
  cat("Preparing final dataset for IPV classifier...\n")
  
  # Step 1: Combine NVDRS variables with text features
  cat("- Combining NVDRS variables with text features...\n")
  ready <- left_join(nvdrs_clean, text_features, by = "id")
  
  # Step 2: Combine with concept scores
  cat("- Adding concept scores...\n")
  ready <- left_join(ready, concept_scores, by = "id")
  
  # Step 3: Handle missing values
  cat("- Handling missing values...\n")
  
  # Count missing values before replacement
  missing_before <- sum(is.na(ready))
  if(missing_before > 0) {
    cat("  Found", missing_before, "missing values\n")
  }
  
  # Replace numeric missing values with 0
  # This is appropriate because missing concept scores indicate no concepts were found
  ready <- ready %>% 
    mutate_if(is.numeric, replace_na, 0)
  
  # Verify no missing values remain
  missing_after <- sum(is.na(ready))
  if(missing_after > 0) {
    cat("  Warning:", missing_after, "missing values remain after replacement\n")
    
    # Identify columns with remaining missing values
    missing_cols <- names(ready)[colSums(is.na(ready)) > 0]
    cat("  Columns with missing values:", paste(missing_cols, collapse = ", "), "\n")
  } else {
    cat("  All missing values handled successfully\n")
  }
  
  # Step 4: Validate dataset structure
  validate_status <- validate_final_dataset(ready)
  
  if(validate_status) {
    cat("\nDataset preparation complete!\n")
    cat("Final dataset has", nrow(ready), "cases and", ncol(ready), "variables\n")
  } else {
    cat("\nWarning: Dataset validation failed. Please check the data.\n")
  }
  
  return(ready)
}

#' Validate the final dataset structure
#' @param dataset Final combined dataset
#' @return Logical indicating if dataset is valid
validate_final_dataset <- function(dataset) {
  
  cat("\nValidating final dataset...\n")
  
  valid <- TRUE
  
  # Check for required ID column
  if(!"id" %in% names(dataset)) {
    cat("Error: Missing required 'id' column\n")
    valid <- FALSE
  }
  
  # Check for text feature columns
  text_cols <- c("sent_syuzhet", "sent_vader", "n_first_person", "n_polite", 
                 "n_second_person", "n_second_personp", "n_third_person")
  missing_text <- setdiff(text_cols, names(dataset))
  if(length(missing_text) > 0) {
    cat("Warning: Missing text feature columns:", paste(missing_text, collapse = ", "), "\n")
  }
  
  # Check for NVDRS variables (at least some key ones)
  key_nvdrs <- c("vdrs_demog_age", "vdrs_demog_male", "vdrs_relat_ipp", 
                 "vdrs_mh_curr", "vdrs_life_crisis")
  missing_nvdrs <- setdiff(key_nvdrs, names(dataset))
  if(length(missing_nvdrs) > 0) {
    cat("Warning: Missing key NVDRS variables:", paste(missing_nvdrs, collapse = ", "), "\n")
  }
  
  # Check for concept score columns (should start with c_)
  concept_cols <- names(dataset)[str_starts(names(dataset), "c_")]
  if(length(concept_cols) < 5) {
    cat("Warning: Found only", length(concept_cols), "concept score columns (expected more)\n")
  }
  
  # Check data types
  numeric_cols <- names(dataset)[sapply(dataset, is.numeric)]
  cat("- Found", length(numeric_cols), "numeric columns\n")
  
  # Check for any remaining missing values
  total_missing <- sum(is.na(dataset))
  if(total_missing > 0) {
    cat("Error: Dataset still contains", total_missing, "missing values\n")
    valid <- FALSE
  }
  
  # Check for duplicate IDs
  if(any(duplicated(dataset$id))) {
    cat("Error: Dataset contains duplicate IDs\n")
    valid <- FALSE
  }
  
  if(valid) {
    cat("Dataset validation passed!\n")
  }
  
  return(valid)
}

#' Get model-ready features from the prepared dataset
#' @param dataset Prepared dataset
#' @return Dataframe with only the features needed for prediction
get_model_features <- function(dataset) {
  
  # Remove administrative columns that aren't used by the model
  admin_cols <- c("id", "state", "incidentyear", "incidentid", "personid", 
                  "narrativecme", "narrativele")
  
  # Remove summary variables (those ending in _SUMM)
  summ_cols <- names(dataset)[str_ends(names(dataset), "_SUMM")]
  
  # Get feature columns (everything except admin and summary columns)
  feature_cols <- setdiff(names(dataset), c(admin_cols, summ_cols))
  
  # Return dataset with ID and features only
  model_data <- dataset %>%
    select(id, all_of(feature_cols))
  
  cat("Selected", ncol(model_data) - 1, "features for modeling\n")
  
  return(model_data)
}

#' Create summary statistics for the prepared dataset
#' @param dataset Prepared dataset
#' @return List of summary statistics
summarize_prepared_data <- function(dataset) {
  
  cat("\nGenerating dataset summary...\n")
  
  summary_stats <- list()
  
  # Basic counts
  summary_stats$n_cases <- nrow(dataset)
  summary_stats$n_variables <- ncol(dataset)
  
  # Demographics summary
  if("vdrs_demog_gender_SUMM" %in% names(dataset)) {
    summary_stats$gender_dist <- table(dataset$vdrs_demog_gender_SUMM)
  }
  
  if("vdrs_demog_age" %in% names(dataset)) {
    summary_stats$age_mean <- mean(dataset$vdrs_demog_age, na.rm = TRUE)
    summary_stats$age_sd <- sd(dataset$vdrs_demog_age, na.rm = TRUE)
  }
  
  # IPV-related variables
  if("vdrs_relat_ipp" %in% names(dataset)) {
    summary_stats$ipp_problem_pct <- mean(dataset$vdrs_relat_ipp) * 100
  }
  
  if("vdrs_ipv_jeal" %in% names(dataset)) {
    summary_stats$ipv_jeal_pct <- mean(dataset$vdrs_ipv_jeal) * 100
  }
  
  # Concept score summaries
  if("c_wtsum_ipv_concepts" %in% names(dataset)) {
    summary_stats$ipv_concepts_mean <- mean(dataset$c_wtsum_ipv_concepts, na.rm = TRUE)
    summary_stats$ipv_concepts_sd <- sd(dataset$c_wtsum_ipv_concepts, na.rm = TRUE)
  }
  
  # Print summary
  cat("\nDataset Summary:\n")
  cat("- Total cases:", summary_stats$n_cases, "\n")
  cat("- Total variables:", summary_stats$n_variables, "\n")
  
  if(!is.null(summary_stats$age_mean)) {
    cat("- Mean age:", round(summary_stats$age_mean, 1), 
        "(SD:", round(summary_stats$age_sd, 1), ")\n")
  }
  
  if(!is.null(summary_stats$ipp_problem_pct)) {
    cat("- Intimate partner problem:", round(summary_stats$ipp_problem_pct, 1), "%\n")
  }
  
  if(!is.null(summary_stats$ipv_concepts_mean)) {
    cat("- Mean IPV concept score:", round(summary_stats$ipv_concepts_mean, 2), "\n")
  }
  
  return(summary_stats)
}