## 03_calculate_concept_scores.R - Calculate Concept Scores from Narratives
## IPV-Related Suicide Classifier
## Purpose: Process narratives and calculate concept scores based on keyword matching

#' Main function to calculate concept scores
#' @param nvdrs_data NVDRS dataframe with narratives
#' @param concept_file Path to concept term lists file
#' @return Dataframe with concept scores
calculate_concept_scores <- function(nvdrs_data, concept_file = "models/concept_020122.Rdata") {
  
  cat("Calculating concept scores from narratives...\n")
  
  # Extract narratives
  nvdrs_narr <- nvdrs_data %>% 
    select(id, narrativecme, narrativele)
  
  # Combine narratives
  nvdrs_narr <- nvdrs_narr %>% 
    mutate(narr = paste(narrativecme, narrativele, sep = " "))
  
  # Step 1: Apply controlled vocabulary
  cat("- Applying controlled vocabulary...\n")
  nvdrs_narr <- apply_controlled_vocabulary(nvdrs_narr)
  
  # Step 2: Clean text
  cat("- Cleaning text...\n")
  nvdrs_narr <- clean_narrative_text(nvdrs_narr)
  
  # Step 3: Load concept terms
  cat("- Loading concept term lists...\n")
  concept_data <- load_concept_terms(concept_file)
  
  # Step 4: Tokenize and match concepts
  cat("- Tokenizing and matching concepts...\n")
  token_data <- tokenize_and_match(nvdrs_narr, concept_data)
  
  # Step 5: Calculate concept scores
  cat("- Calculating TF-RF weighted concept scores...\n")
  concept_scores <- calculate_tf_rf_scores(token_data, concept_data$concept)
  
  cat("Concept score calculation complete!\n")
  return(concept_scores)
}

#' Apply controlled vocabulary to narratives
#' @param nvdrs_narr Dataframe with narrative text
#' @return Dataframe with controlled vocabulary applied
apply_controlled_vocabulary <- function(nvdrs_narr) {
  
  # Intimate partner terms
  iipp_list <- c("boyfriend", "girlfriend", "wife", "husband", 
                 "spouse", "partner", "gf", "bf", "lover", 
                 "fiancee", "fiance", "married", "marriage")
  iipp_regex <- paste(iipp_list, collapse = "|")
  
  # Replace IP terms with standardized token
  nvdrs_narr$narr <- gsub(iipp_regex, "iipp", nvdrs_narr$narr)
  
  # Handle multi-word phrases
  nvdrs_narr$narr <- gsub("intimate partner", "iipp", nvdrs_narr$narr)
  nvdrs_narr$narr <- gsub("dating partner", "iipp", nvdrs_narr$narr)
  nvdrs_narr$narr <- gsub("significant other", "iipp", nvdrs_narr$narr)
  nvdrs_narr$narr <- gsub("romantic relationship", "iipp", nvdrs_narr$narr)
  nvdrs_narr$narr <- gsub("romantic relations", "iipp", nvdrs_narr$narr)
  nvdrs_narr$narr <- gsub("ex-iipp", "ex iipp", nvdrs_narr$narr)
  
  # Ex-partner terms
  ex_list <- c("ex", "former", "formerly", "estranged", "breakup", 
               "separate", "separated", "separating", 
               "divorce", "divorced", "divorcing")
  ex_regex <- paste(ex_list, collapse = "|")
  nvdrs_narr$narr <- gsub(ex_regex, "ex", nvdrs_narr$narr)
  
  # Additional ex-partner phrases
  ex_phrases <- c("ex dating", "ex dated", "ex couple", "formerly dating",
                  "formerly dated", "former couple", "formerly married",
                  "no longer dating", "no longer married", "previously married",
                  "previously dated", "exgirlfriend", "exboyfriend",
                  "exhusband", "exwife", "exspouse")
  
  for(phrase in ex_phrases) {
    if(grepl("ex[a-z]", phrase)) {
      # For compound words like "exgirlfriend"
      nvdrs_narr$narr <- gsub(phrase, "ex iipp", nvdrs_narr$narr)
    } else {
      nvdrs_narr$narr <- gsub(phrase, "ex", nvdrs_narr$narr)
    }
  }
  
  # Remove victim/decedent references
  v_terms <- c("victim", "decedent", "deceased", "\\bv\\b", "\\bd\\b")
  v_regex <- paste(v_terms, collapse = "|")
  nvdrs_narr$narr <- gsub(v_regex, "", nvdrs_narr$narr)
  
  # Clean up formatting
  nvdrs_narr$narr <- gsub("\\.(?=[A-Za-z])", ". ", nvdrs_narr$narr, perl = TRUE)
  nvdrs_narr$narr <- gsub("#", "", nvdrs_narr$narr, perl = TRUE)
  
  # Apply CP/W/RP replacements
  nvdrs_narr <- apply_reporting_party_replacements(nvdrs_narr)
  
  return(nvdrs_narr)
}

#' Apply reporting party replacements
#' @param nvdrs_narr Dataframe with narratives
#' @return Dataframe with RP/CP/W replacements
apply_reporting_party_replacements <- function(nvdrs_narr) {
  
  # Use the helper functions from the original code
  nvdrs_narr <- nvdrs_narr %>% 
    mutate(new_text = narr %>% sub_if_close("reporting party ", "\\b(rp|RP)\\b", "iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close("the reporting party", "\\b(rp|RP)\\b", "iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close("\\brp\\b", "\\b(rp|RP)\\b", "iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close("concerned party", "\\b(cp|CP)\\b", "iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close("the concerned party", "\\b(cp|CP)\\b", "iipp")) %>% 
    mutate(new_text = new_text %>% sub_if_close("\\bcp\\b", "\\b(cp|CP)\\b", "iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close("involved party", "\\b(IP|ip)\\b", "iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close("the involved party", "\\b(IP|ip)\\b", "iipp")) %>%
    mutate(new_text = new_text %>% sub_if_close("witness", "\\b(W|w)\\b", "iipp"))
  
  nvdrs_narr <- nvdrs_narr %>%
    select(-narr) %>% 
    rename(narr = new_text)
  
  return(nvdrs_narr)
}

#' Clean narrative text
#' @param nvdrs_narr Dataframe with narratives
#' @return Dataframe with cleaned text
clean_narrative_text <- function(nvdrs_narr) {
  
  # Replace 911 with police
  nvdrs_narr$narr <- gsub("911", "police", nvdrs_narr$narr)
  
  # Remove numbers
  nvdrs_narr$narr <- gsub('[[:digit:]]+', '', nvdrs_narr$narr)
  
  # Handle contractions
  nvdrs_narr$narr <- gsub("won't", "should", nvdrs_narr$narr)
  
  # Remove non-English characters
  nvdrs_narr$narr <- gsub("[^0-9A-Za-z\\.///' ]", "", nvdrs_narr$narr, ignore.case = TRUE)
  
  # Remove possessive s
  nvdrs_narr$narr <- gsub("'s", "", nvdrs_narr$narr, ignore.case = TRUE)
  
  # Remove special characters and line breaks
  nvdrs_narr$narr <- gsub('[ÃåââãåÅâÂ]', '', nvdrs_narr$narr)
  nvdrs_narr$narr <- gsub("[\n]", " ", nvdrs_narr$narr)
  
  # Clean spacing
  nvdrs_narr$narr <- gsub("\\.(?=[A-Za-z])", ". ", nvdrs_narr$narr, perl = TRUE)
  
  # Convert to sentence case
  nvdrs_narr$narr <- str_to_sentence(nvdrs_narr$narr, locale = "en")
  
  return(nvdrs_narr)
}

#' Load concept term lists
#' @param concept_file Path to concept Rdata file
#' @return List of concept dataframes by n-gram type
load_concept_terms <- function(concept_file) {
  
  # Load the concept data
  load(file = concept_file)
  
  # Assume the loaded object is named 'concept'
  # Separate by n-gram type and stemming requirements
  concept_uni_stem <- concept %>% 
    filter(ngram == 1 & do_not_stem == 0)
  
  concept_uni_nostem <- concept %>% 
    filter(ngram == 1 & do_not_stem == 1)
  
  concept_bi <- concept %>% 
    filter(ngram == 2)
  
  concept_tri <- concept %>% 
    filter(ngram == 3)
  
  return(list(
    concept = concept,
    uni_stem = concept_uni_stem,
    uni_nostem = concept_uni_nostem,
    bi = concept_bi,
    tri = concept_tri
  ))
}

#' Tokenize narratives and match to concepts
#' @param nvdrs_narr Dataframe with narratives
#' @param concept_data List of concept dataframes
#' @return Combined token dataframe
tokenize_and_match <- function(nvdrs_narr, concept_data) {
  
  # Split into sentences
  sent <- nvdrs_narr %>%
    unnest_tokens(output = sentence, input = narr, token = "sentences", drop = FALSE) %>%
    mutate(sentence_OG = sentence)
  
  # Process unigrams
  word <- sent %>%  
    unnest_tokens(output = word, input = sentence, token = "words", drop = FALSE) %>%
    filter(str_length(word) >= 2) %>% 
    filter(str_length(word) <= 14) %>%
    mutate(stem = tolower(SnowballC::wordStem(word))) %>%
    left_join(concept_data$uni_stem %>% mutate(theor = 1) %>% 
              select(stem, theor, concept, token_root), by = "stem") %>% 
    left_join(concept_data$uni_nostem %>% mutate(theor = 1, not_stem = 1) %>% 
              rename(word = token) %>% 
              select(word, theor, concept, token_root, not_stem), by = "word") %>% 
    mutate(token = case_when(not_stem == 1 ~ word,
                            TRUE ~ stem),
           concept = case_when(!is.na(concept.x) ~ concept.x, 
                              !is.na(concept.y) ~ concept.y),
           token_root = case_when(!is.na(token_root.x) ~ token_root.x, 
                                 !is.na(token_root.y) ~ token_root.y)) %>% 
    filter(theor.x == 1 | theor.y == 1) %>% 
    select(id, sentence, sentence_OG, token, token_root, concept)
  
  # Process bigrams
  bigram <- sent %>%  
    unnest_tokens(output = ngram, input = sentence, token = "ngrams", n = 2, drop = FALSE) %>%
    mutate(stem = stem_strings(ngram)) %>%
    left_join(concept_data$bi %>% mutate(theor = 1) %>% 
              select(stem, theor, concept, token_root), by = "stem") %>% 
    filter(theor == 1) %>% 
    rename(token = stem) %>% 
    select(id, sentence, sentence_OG, token, token_root, concept)
  
  # Process trigrams
  trigram <- sent %>%  
    unnest_tokens(output = ngram, input = sentence, token = "ngrams", n = 3, drop = FALSE) %>%
    mutate(stem = stem_strings(ngram)) %>%
    left_join(concept_data$tri %>% mutate(theor = 1) %>% 
              select(stem, theor, concept, token_root), by = "stem") %>% 
    filter(theor == 1) %>% 
    rename(token = stem) %>% 
    select(id, sentence, sentence_OG, token, token_root, concept)
  
  # Combine all tokens
  token <- rbind(word, bigram, trigram)
  
  # Add rf values
  token <- token %>%
    left_join(concept_data$concept %>% select(token_root, rf) %>% unique(), 
              by = "token_root") %>% 
    arrange(id)
  
  return(token)
}

#' Calculate TF-RF weighted concept scores
#' @param token_data Token dataframe with matched concepts
#' @param concept_list Full concept data for validation
#' @return Dataframe with concept scores per case
calculate_tf_rf_scores <- function(token_data, concept_list) {
  
  # Calculate TF-RF weighted concept scores
  case_concept <- token_data %>% 
    mutate(tf = 1) %>% 
    group_by(id, token_root, concept) %>%
    summarize(tf = sum(tf),
              rf = mean(rf), .groups = "drop") %>%  
    mutate(tf_rf = tf * rf) %>% 
    group_by(id, concept) %>%
    summarize(tf_rf = sum(tf_rf), .groups = "drop") %>% 
    pivot_wider(id_cols = id, 
                names_from = concept,
                values_from = tf_rf, 
                values_fill = 0) %>%
    as_tibble()
  
  # Create summary scores
  case_concept <- case_concept %>% 
    mutate(
      wtsum_ipv_concepts = rowSums(select(., any_of(c(
        "harm_other", "harm_emot", "harm_sex", "harm_phys", 
        "fear", "evade", "economic", "jeal", "deceipt", "control", 
        "rev", "witness", "pics", "ip_place", "property", 
        "danger_person", "danger_weapon", "stalk", 
        "threat", "threat_suicide", "abuse", "dvpo"
      ))), na.rm = TRUE),
      wtsum_condit_pattern = rowSums(select(., any_of(c(
        "aux_condit", "pattern", "self_harm", "argue"
      ))), na.rm = TRUE)
    )
  
  # Add prefix to concept variables
  case_concept <- case_concept %>% 
    setNames(paste0('c_', names(.))) %>%
    rename(id = c_id)
  
  return(case_concept)
}

# ===== HELPER FUNCTIONS =====

#' Find starting positions of text string
find_start_spots <- function(txt, txt_to_find) {
  str_locate_all(tolower(txt), tolower(txt_to_find)) %>% 
    `[[`(1) %>% as_tibble() %>% pull(start)
}

#' Check if two strings are close together
are_vectors_close <- function(term1_vec, term2_vec, num_dist = 8, verbose = F) {
  if((length(term1_vec) == 0) | (length(term2_vec) == 0)) {return(F)}
  distance_tbl <- expand_grid(term1_vec, term2_vec) %>% 
    mutate(distance = abs(term1_vec - term2_vec)) %>% 
    mutate(is_close_enough = distance <= num_dist)
  
  if(verbose) print(distance_tbl)
  return(any(distance_tbl$is_close_enough))
}

#' Replace text if close to IP reference
sub_if_close <- function(txt, find_rp_txt, remove_rp_txt, ip_txt) {
  
  rp_pos <- txt %>% map(find_start_spots, find_rp_txt) 
  ip_pos <- txt %>% map(find_start_spots, ip_txt)
  
  should_replace <- map2_chr(rp_pos, ip_pos, are_vectors_close)
  
  text_tbl <- tibble(original_txt = txt, should_replace) %>%
    mutate(new_text = if_else(should_replace == T, 
                              original_txt %>% str_replace_all(remove_rp_txt, ip_txt), 
                              original_txt))
  return(text_tbl$new_text)
}

#' Stem multi-word strings
stem_strings <- function(x) {
  sapply(strsplit(x, " "), function(words) {
    paste(wordStem(words), collapse = " ")
  })
}