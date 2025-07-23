## 01_load_data.R - Load and Prepare NVDRS Data
## IPV-Related Suicide Classifier
## Purpose: Functions to load NVDRS RAD file and required model components

#' Load NVDRS RAD File
#' @param file_path Path to NVDRS RAD file (Rdata format)
#' @return Cleaned NVDRS dataframe with single suicides only
load_nvdrs_data <- function(file_path) {
  
  # Load NVDRS RAD file
  cat("Loading NVDRS RAD file...\n")
  load(file = file_path)
  
  # Convert variable names to lowercase
  names(nvdrs) <- tolower(names(nvdrs))
  
  # Organize variables alphabetically
  nvdrs <- nvdrs %>% select(sort(names(.)))
  
  # Create unique identifier (ID) variable
  nvdrs <- nvdrs %>% 
    mutate(id = paste(siteid, incidentyear, incidentid, personid, sep = "-"))
  
  # Filter for single suicide events only
  # IPV classifier should NOT be applied to homicide-suicides
  nvdrs_ss <- nvdrs %>% 
    filter(incidentcategory_c == "Single suicide")
  
  # Print summary information
  cat("Data loaded successfully!\n")
  cat("Total single suicides:", nrow(nvdrs_ss), "\n")
  
  # Show year distribution
  year_counts <- nvdrs_ss %>% count(incidentyear)
  cat("\nSuicides by year:\n")
  print(year_counts)
  
  return(nvdrs_ss)
}

#' Load Concept Term Lists
#' @param concept_file Path to concept Rdata file
#' @return Loaded concept data
load_concept_data <- function(concept_file = "models/concept_020122.Rdata") {
  
  cat("Loading concept term lists...\n")
  load(file = concept_file)
  
  # The load() function will create objects in the environment
  # Return the loaded concepts (assumes object is named 'concepts')
  if(exists("concepts")) {
    cat("Concept data loaded successfully!\n")
    return(concepts)
  } else {
    # If the object has a different name, we'll need to identify it
    # Get all objects loaded from the file
    loaded_objects <- ls()
    cat("Loaded objects:", paste(loaded_objects, collapse = ", "), "\n")
    return(NULL)
  }
}

#' Load IPV Classifier Model
#' @param model_file Path to IPV classifier model Rdata file
#' @return Loaded model object
load_ipv_model <- function(model_file = "models/IPV_Related_Suicide_rfmodel_2022_01_28.Rdata") {
  
  cat("Loading IPV classifier model...\n")
  
  # Store current environment objects
  before_load <- ls()
  
  # Load the model
  load(file = model_file)
  
  # Find what was loaded
  after_load <- ls()
  new_objects <- setdiff(after_load, before_load)
  
  if(length(new_objects) > 0) {
    cat("Model loaded successfully!\n")
    cat("Loaded objects:", paste(new_objects, collapse = ", "), "\n")
    
    # Return the first loaded object (should be the model)
    return(get(new_objects[1]))
  } else {
    stop("No model object was loaded from the file")
  }
}

#' Load All Required Data for IPV Classifier
#' @param nvdrs_file Path to NVDRS RAD file
#' @param concept_file Path to concept term lists file
#' @param model_file Path to IPV classifier model file
#' @return List containing all loaded data
load_all_data <- function(nvdrs_file,
                         concept_file = "models/concept_020122.Rdata",
                         model_file = "models/IPV_Related_Suicide_rfmodel_2022_01_28.Rdata") {
  
  cat("========================================\n")
  cat("Loading all data for IPV Classifier\n")
  cat("========================================\n\n")
  
  # Load NVDRS data
  nvdrs_data <- load_nvdrs_data(nvdrs_file)
  
  cat("\n")
  
  # Load concept data
  concept_data <- load_concept_data(concept_file)
  
  cat("\n")
  
  # Load model
  model <- load_ipv_model(model_file)
  
  cat("\n========================================\n")
  cat("All data loaded successfully!\n")
  cat("========================================\n")
  
  return(list(
    nvdrs = nvdrs_data,
    concepts = concept_data,
    model = model
  ))
}