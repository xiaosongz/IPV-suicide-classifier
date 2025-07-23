## 02_extract_text_features.R - Extract Text-Based Features
## IPV-Related Suicide Classifier
## Purpose: Extract sentiment and grammatical features from death narratives

#' Extract Text Features from NVDRS Narratives
#' @param nvdrs_data NVDRS dataframe with narrative columns
#' @return Dataframe with text features extracted
extract_text_features <- function(nvdrs_data) {
  
  cat("Extracting text-based features from narratives...\n")
  
  # Step 1: Extract narratives
  # Keep only ID and narrative columns for efficiency
  nvdrs_narr <- nvdrs_data %>% 
    select(id, narrativecme, narrativele)
  
  cat("- Combining CME and LE narratives...\n")
  
  # Step 2: Combine CME and LE narratives
  # Some narratives may have missing values, handle with care
  nvdrs_narr <- nvdrs_narr %>% 
    mutate(narr = paste(narrativecme, narrativele, sep = " "))
  
  # Step 3: Extract features using textfeatures package
  cat("- Extracting sentiment scores and grammatical features...\n")
  cat("  (This may take a few minutes for large datasets)\n")
  
  txt_feat <- textfeatures(
    nvdrs_narr$narr, 
    sentiment = TRUE,      # Calculate sentiment scores
    word_dims = 0,         # Don't calculate word embeddings
    normalize = FALSE      # Don't normalize features
  ) %>%
  bind_cols(nvdrs_narr %>% select(id))
  
  # Step 4: Keep only required features for IPV classifier
  # These specific features were selected during model development
  txt_feat <- txt_feat %>% 
    select(
      id, 
      sent_syuzhet,      # Syuzhet sentiment score
      sent_vader,        # VADER sentiment score
      n_first_person,    # Count of first person pronouns
      n_polite,          # Count of polite words
      n_second_person,   # Count of second person pronouns
      n_second_personp,  # Proportion of second person pronouns
      n_third_person     # Count of third person pronouns
    )
  
  # Print summary statistics
  cat("\nText features extracted successfully!\n")
  cat("Total cases processed:", nrow(txt_feat), "\n")
  
  # Check for any missing values
  missing_counts <- colSums(is.na(txt_feat))
  if(any(missing_counts > 0)) {
    cat("\nWarning: Missing values detected in text features:\n")
    print(missing_counts[missing_counts > 0])
  }
  
  return(txt_feat)
}

#' Process Text Features with Error Handling
#' @param nvdrs_data NVDRS dataframe
#' @return Text features dataframe or NULL if error
extract_text_features_safe <- function(nvdrs_data) {
  
  tryCatch({
    # Check if required columns exist
    required_cols <- c("id", "narrativecme", "narrativele")
    missing_cols <- setdiff(required_cols, names(nvdrs_data))
    
    if(length(missing_cols) > 0) {
      stop(paste("Missing required columns:", paste(missing_cols, collapse = ", ")))
    }
    
    # Extract features
    features <- extract_text_features(nvdrs_data)
    
    return(features)
    
  }, error = function(e) {
    cat("Error extracting text features:\n")
    cat(e$message, "\n")
    return(NULL)
  })
}

#' Validate Text Features
#' @param txt_feat Text features dataframe
#' @return Logical indicating if features are valid
validate_text_features <- function(txt_feat) {
  
  cat("\nValidating text features...\n")
  
  # Check if dataframe exists and has rows
  if(is.null(txt_feat) || nrow(txt_feat) == 0) {
    cat("Error: No text features found\n")
    return(FALSE)
  }
  
  # Check for required columns
  required_cols <- c("id", "sent_syuzhet", "sent_vader", 
                    "n_first_person", "n_polite", 
                    "n_second_person", "n_second_personp", 
                    "n_third_person")
  
  missing_cols <- setdiff(required_cols, names(txt_feat))
  if(length(missing_cols) > 0) {
    cat("Error: Missing required columns:", paste(missing_cols, collapse = ", "), "\n")
    return(FALSE)
  }
  
  # Check for reasonable values
  # Sentiment scores should be numeric
  if(!is.numeric(txt_feat$sent_syuzhet) || !is.numeric(txt_feat$sent_vader)) {
    cat("Error: Sentiment scores must be numeric\n")
    return(FALSE)
  }
  
  # Counts should be non-negative
  count_cols <- c("n_first_person", "n_polite", "n_second_person", "n_third_person")
  for(col in count_cols) {
    if(any(txt_feat[[col]] < 0, na.rm = TRUE)) {
      cat("Error: Negative values found in", col, "\n")
      return(FALSE)
    }
  }
  
  cat("Text features validation passed!\n")
  return(TRUE)
}