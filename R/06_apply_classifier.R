## 06_apply_classifier.R - Apply IPV Classifier Model
## IPV-Related Suicide Classifier
## Purpose: Apply the pre-trained Random Forest model to make IPV predictions

#' Apply IPV classifier to prepared dataset
#' @param prepared_data Dataset prepared with all required features
#' @param model_object Pre-trained Random Forest model
#' @param probability_threshold Threshold for positive classification (default 0.5)
#' @return Dataframe with predictions
apply_ipv_classifier <- function(prepared_data, model_object, probability_threshold = 0.5) {
  
  cat("Applying IPV classifier...\n")
  
  # Make predictions
  cat("- Generating predictions for", nrow(prepared_data), "cases...\n")
  
  # Get probability predictions
  pred <- predict(model_object, prepared_data, type = "prob") %>% 
    bind_cols(prepared_data %>% select(id))
  
  # Apply threshold to determine class
  pred <- pred %>%
    mutate(pred_class = ifelse(.pred_yes > probability_threshold, 1, 2))
  
  # Code the predicted class as a factor
  pred$pred_class <- factor(pred$pred_class,
                           levels = c(1, 2),
                           labels = c("yes", "no"))
  
  # Print summary
  cat("\nPrediction summary:\n")
  pred_summary <- table(pred$pred_class)
  cat("- IPV-related (yes):", pred_summary["yes"], "cases\n")
  cat("- Not IPV-related (no):", pred_summary["no"], "cases\n")
  cat("- Proportion IPV-related:", 
      round(pred_summary["yes"] / sum(pred_summary) * 100, 1), "%\n")
  
  return(pred)
}

#' Get detailed prediction results with case information
#' @param predictions Prediction dataframe
#' @param original_data Original dataset with case information
#' @return Enhanced prediction dataframe
get_detailed_predictions <- function(predictions, original_data) {
  
  cat("\nCreating detailed prediction results...\n")
  
  # Select relevant case information
  case_info <- original_data %>%
    select(id, 
           incidentyear,
           state,
           vdrs_demog_age,
           vdrs_demog_gender_SUMM,
           vdrs_demog_race_eth_SUMM,
           vdrs_relat_ipp,
           vdrs_ipv_jeal,
           n_narr_len) %>%
    # Rename for clarity
    rename(
      age = vdrs_demog_age,
      gender = vdrs_demog_gender_SUMM,
      race_ethnicity = vdrs_demog_race_eth_SUMM,
      intimate_partner_problem = vdrs_relat_ipp,
      ipv_jealousy = vdrs_ipv_jeal,
      narrative_length = n_narr_len
    )
  
  # Combine with predictions
  detailed_results <- predictions %>%
    left_join(case_info, by = "id") %>%
    # Reorder columns
    select(id, pred_class, .pred_yes, .pred_no, everything()) %>%
    # Add confidence score
    mutate(
      confidence = pmax(.pred_yes, .pred_no),
      confidence_category = case_when(
        confidence >= 0.8 ~ "High",
        confidence >= 0.6 ~ "Moderate",
        TRUE ~ "Low"
      )
    )
  
  return(detailed_results)
}

#' Analyze prediction patterns
#' @param detailed_predictions Detailed prediction results
#' @return List of analysis results
analyze_prediction_patterns <- function(detailed_predictions) {
  
  cat("\nAnalyzing prediction patterns...\n")
  
  analysis <- list()
  
  # Overall predictions
  analysis$overall <- detailed_predictions %>%
    count(pred_class) %>%
    mutate(proportion = n / sum(n))
  
  # By confidence level
  analysis$by_confidence <- detailed_predictions %>%
    group_by(pred_class, confidence_category) %>%
    count() %>%
    group_by(pred_class) %>%
    mutate(proportion = n / sum(n))
  
  # By demographic factors (if available)
  if("gender" %in% names(detailed_predictions)) {
    analysis$by_gender <- detailed_predictions %>%
      filter(!is.na(gender)) %>%
      group_by(gender) %>%
      summarize(
        n_total = n(),
        n_ipv = sum(pred_class == "yes"),
        pct_ipv = n_ipv / n_total * 100,
        avg_prob_ipv = mean(.pred_yes)
      )
  }
  
  if("age" %in% names(detailed_predictions)) {
    analysis$by_age_group <- detailed_predictions %>%
      filter(!is.na(age)) %>%
      mutate(age_group = cut(age, 
                            breaks = c(0, 24, 40, 54, 70, Inf),
                            labels = c("<25", "25-40", "41-54", "55-70", "71+"))) %>%
      group_by(age_group) %>%
      summarize(
        n_total = n(),
        n_ipv = sum(pred_class == "yes"),
        pct_ipv = n_ipv / n_total * 100,
        avg_prob_ipv = mean(.pred_yes),
        .groups = "drop"
      )
  }
  
  # Print key findings
  cat("\nKey findings:\n")
  cat("- Total IPV-related cases:", 
      sum(detailed_predictions$pred_class == "yes"), "\n")
  cat("- Average IPV probability:", 
      round(mean(detailed_predictions$.pred_yes), 3), "\n")
  
  high_conf_ipv <- detailed_predictions %>%
    filter(pred_class == "yes" & confidence_category == "High") %>%
    nrow()
  cat("- High confidence IPV predictions:", high_conf_ipv, "\n")
  
  return(analysis)
}

#' Export prediction results
#' @param predictions Prediction results to export
#' @param output_file Path for output CSV file
#' @param include_probabilities Whether to include probability columns
export_predictions <- function(predictions, 
                             output_file = "ipv_predictions.csv",
                             include_probabilities = TRUE) {
  
  cat("\nExporting predictions to:", output_file, "\n")
  
  # Select columns to export
  if(include_probabilities) {
    export_data <- predictions
  } else {
    export_data <- predictions %>%
      select(-starts_with(".pred_"))
  }
  
  # Write to CSV
  write.csv(export_data, file = output_file, row.names = FALSE)
  
  cat("Export complete. File contains", nrow(export_data), 
      "cases with", ncol(export_data), "columns.\n")
}

#' Validate model requirements before prediction
#' @param data Dataset to validate
#' @param model Model object
#' @return Logical indicating if requirements are met
validate_model_requirements <- function(data, model) {
  
  cat("\nValidating model requirements...\n")
  
  valid <- TRUE
  
  # Check if model object exists and is correct type
  if(is.null(model)) {
    cat("Error: Model object is NULL\n")
    return(FALSE)
  }
  
  # Get expected features from model (this may vary by model type)
  # For tidymodels workflow, you might need: model$pre$mold$predictors
  
  # Check for minimum required columns
  # These are examples - adjust based on your actual model
  min_required <- c("vdrs_demog_age", "vdrs_demog_male", "vdrs_relat_ipp")
  missing <- setdiff(min_required, names(data))
  
  if(length(missing) > 0) {
    cat("Error: Missing required columns:", paste(missing, collapse = ", "), "\n")
    valid <- FALSE
  }
  
  # Check for no missing values in numeric columns
  numeric_cols <- names(data)[sapply(data, is.numeric)]
  missing_counts <- colSums(is.na(data[numeric_cols]))
  
  if(any(missing_counts > 0)) {
    cat("Error: Missing values found in numeric columns\n")
    print(missing_counts[missing_counts > 0])
    valid <- FALSE
  }
  
  if(valid) {
    cat("All model requirements satisfied!\n")
  }
  
  return(valid)
}