## utils.R - Utility Functions for IPV Classifier
## IPV-Related Suicide Classifier
## Purpose: Helper functions for text processing and data manipulation

# ===== TEXT PROCESSING HELPERS =====

#' Find starting positions of text string in narrative
#' @param txt Text to search in
#' @param txt_to_find Text to find
#' @return Vector of starting positions
find_start_spots <- function(txt, txt_to_find) {
  str_locate_all(tolower(txt), tolower(txt_to_find)) %>% 
    `[[`(1) %>% 
    as_tibble() %>% 
    pull(start)
}

#' Check if two text positions are close together
#' @param term1_vec Vector of positions for term 1
#' @param term2_vec Vector of positions for term 2
#' @param num_dist Maximum distance to consider "close" (default 8)
#' @param verbose Whether to print distance table
#' @return Logical indicating if terms are close
are_vectors_close <- function(term1_vec, term2_vec, num_dist = 8, verbose = FALSE) {
  if((length(term1_vec) == 0) | (length(term2_vec) == 0)) {
    return(FALSE)
  }
  
  distance_tbl <- expand_grid(term1_vec, term2_vec) %>% 
    mutate(distance = abs(term1_vec - term2_vec)) %>% 
    mutate(is_close_enough = distance <= num_dist)
  
  if(verbose) print(distance_tbl)
  
  return(any(distance_tbl$is_close_enough))
}

#' Replace text if close to another term
#' @param txt Text to process
#' @param find_rp_txt Text to find (reporting party variant)
#' @param remove_rp_txt Regex pattern to remove
#' @param ip_txt Replacement text (intimate partner)
#' @return Modified text
sub_if_close <- function(txt, find_rp_txt, remove_rp_txt, ip_txt) {
  
  rp_pos <- txt %>% map(find_start_spots, find_rp_txt) 
  ip_pos <- txt %>% map(find_start_spots, ip_txt)
  
  should_replace <- map2_chr(rp_pos, ip_pos, are_vectors_close)
  
  text_tbl <- tibble(original_txt = txt, should_replace) %>%
    mutate(new_text = if_else(should_replace == TRUE, 
                              original_txt %>% str_replace_all(remove_rp_txt, ip_txt), 
                              original_txt))
  
  return(text_tbl$new_text)
}

#' Stem multi-word strings
#' @param x Character vector of strings to stem
#' @return Character vector with stemmed words
stem_strings <- function(x) {
  sapply(strsplit(x, " "), function(words) {
    paste(wordStem(words), collapse = " ")
  })
}

# ===== DATA VALIDATION HELPERS =====

#' Check if required columns exist in dataframe
#' @param data Dataframe to check
#' @param required_cols Character vector of required column names
#' @return List with validation status and missing columns
check_required_columns <- function(data, required_cols) {
  
  missing_cols <- setdiff(required_cols, names(data))
  
  result <- list(
    valid = length(missing_cols) == 0,
    missing_columns = missing_cols
  )
  
  if(!result$valid) {
    cat("Missing required columns:", paste(missing_cols, collapse = ", "), "\n")
  }
  
  return(result)
}

#' Create placeholder columns for missing variables
#' @param data Dataframe
#' @param column_names Character vector of column names to create
#' @param default_value Default value for new columns (default 0)
#' @return Dataframe with added columns
add_missing_columns <- function(data, column_names, default_value = 0) {
  
  existing_cols <- names(data)
  cols_to_add <- setdiff(column_names, existing_cols)
  
  if(length(cols_to_add) > 0) {
    cat("Adding", length(cols_to_add), "missing columns with default value", 
        default_value, "\n")
    
    for(col in cols_to_add) {
      data[[col]] <- default_value
    }
  }
  
  return(data)
}

# ===== REPORTING HELPERS =====

#' Generate summary report for IPV predictions
#' @param predictions Prediction results
#' @param output_file Optional file path to save report
#' @return Summary statistics
generate_prediction_report <- function(predictions, output_file = NULL) {
  
  cat("\n========================================\n")
  cat("IPV Classifier Prediction Report\n")
  cat("========================================\n\n")
  
  # Overall summary
  total_cases <- nrow(predictions)
  ipv_cases <- sum(predictions$pred_class == "yes")
  ipv_rate <- ipv_cases / total_cases * 100
  
  cat("Total cases analyzed:", total_cases, "\n")
  cat("IPV-related suicides:", ipv_cases, sprintf("(%.1f%%)", ipv_rate), "\n")
  cat("Non-IPV suicides:", total_cases - ipv_cases, 
      sprintf("(%.1f%%)", 100 - ipv_rate), "\n\n")
  
  # Probability distribution
  cat("IPV Probability Distribution:\n")
  prob_summary <- summary(predictions$.pred_yes)
  print(prob_summary)
  cat("\n")
  
  # Confidence levels
  if("confidence_category" %in% names(predictions)) {
    cat("Prediction Confidence:\n")
    conf_table <- table(predictions$confidence_category)
    print(conf_table)
    cat("\n")
  }
  
  # Save report if requested
  if(!is.null(output_file)) {
    sink(output_file)
    cat("IPV Classifier Prediction Report\n")
    cat("Generated:", Sys.Date(), "\n")
    cat("=====================================\n\n")
    cat("Total cases:", total_cases, "\n")
    cat("IPV-related:", ipv_cases, sprintf("(%.1f%%)", ipv_rate), "\n")
    cat("\nProbability Summary:\n")
    print(prob_summary)
    sink()
    cat("Report saved to:", output_file, "\n")
  }
  
  return(list(
    total = total_cases,
    ipv_count = ipv_cases,
    ipv_rate = ipv_rate,
    prob_summary = prob_summary
  ))
}

#' Create a confusion matrix style comparison
#' @param predictions Predictions with known truth (if available)
#' @param truth_column Name of truth column (if exists)
#' @return Confusion matrix or NA
create_confusion_matrix <- function(predictions, truth_column = NULL) {
  
  if(!is.null(truth_column) && truth_column %in% names(predictions)) {
    
    cat("\nConfusion Matrix:\n")
    conf_mat <- table(
      Predicted = predictions$pred_class,
      Actual = predictions[[truth_column]]
    )
    print(conf_mat)
    
    # Calculate metrics if possible
    if(nrow(conf_mat) == 2 && ncol(conf_mat) == 2) {
      accuracy <- sum(diag(conf_mat)) / sum(conf_mat)
      cat("\nAccuracy:", round(accuracy * 100, 1), "%\n")
    }
    
    return(conf_mat)
  } else {
    cat("\nNo truth column available for confusion matrix\n")
    return(NA)
  }
}

# ===== CONCEPT TERM LISTS =====

#' Get default intimate partner term lists
#' @return List containing IP terms and ex-partner terms
get_default_ip_terms <- function() {
  
  ip_terms <- list(
    # Current intimate partner terms
    current = c("boyfriend", "girlfriend", "wife", "husband", 
                "spouse", "partner", "gf", "bf", "lover", 
                "fiancee", "fiance", "married", "marriage"),
    
    # Multi-word current IP phrases
    current_phrases = c("intimate partner", "dating partner", 
                       "significant other", "romantic relationship", 
                       "romantic relations"),
    
    # Ex-partner terms
    ex = c("ex", "former", "formerly", "estranged", "breakup", 
           "separate", "separated", "separating", 
           "divorce", "divorced", "divorcing"),
    
    # Ex-partner phrases
    ex_phrases = c("ex dating", "ex dated", "ex couple", 
                   "formerly dating", "formerly dated", "former couple", 
                   "formerly married", "no longer dating", 
                   "no longer married", "previously married", 
                   "previously dated"),
    
    # Compound ex terms
    ex_compound = c("exgirlfriend", "exboyfriend", "exhusband", 
                    "exwife", "exspouse")
  )
  
  return(ip_terms)
}

# ===== FILE HANDLING HELPERS =====

#' Safely load RData file and return object
#' @param file_path Path to RData file
#' @return Loaded object or NULL if error
safe_load_rdata <- function(file_path) {
  
  if(!file.exists(file_path)) {
    cat("Error: File not found:", file_path, "\n")
    return(NULL)
  }
  
  # Create temporary environment to load into
  temp_env <- new.env()
  
  tryCatch({
    # Load into temporary environment
    load(file_path, envir = temp_env)
    
    # Get loaded objects
    loaded_objects <- ls(envir = temp_env)
    
    if(length(loaded_objects) == 1) {
      # Return the single object
      return(get(loaded_objects[1], envir = temp_env))
    } else if(length(loaded_objects) > 1) {
      cat("Warning: Multiple objects loaded from", file_path, "\n")
      cat("Objects:", paste(loaded_objects, collapse = ", "), "\n")
      # Return the entire environment as a list
      return(as.list(temp_env))
    } else {
      cat("Error: No objects loaded from", file_path, "\n")
      return(NULL)
    }
    
  }, error = function(e) {
    cat("Error loading file:", file_path, "\n")
    cat("Error message:", e$message, "\n")
    return(NULL)
  })
}

#' Print session information for reproducibility
#' @param output_file Optional file to save session info
print_session_info <- function(output_file = NULL) {
  
  cat("\n========================================\n")
  cat("IPV Classifier Session Information\n")
  cat("========================================\n")
  cat("Date:", Sys.Date(), "\n")
  cat("Time:", format(Sys.time(), "%H:%M:%S"), "\n\n")
  
  if(!is.null(output_file)) {
    sink(output_file)
  }
  
  sessionInfo()
  
  if(!is.null(output_file)) {
    sink()
    cat("\nSession info saved to:", output_file, "\n")
  }
}