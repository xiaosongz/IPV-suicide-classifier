## 00_setup.R - Setup and Load Required Libraries
## IPV-Related Suicide Classifier
## Purpose: Install missing packages and load all required R packages

# Function to check and install packages
check_and_install_packages <- function(packages) {
  # Get list of installed packages
  installed_packages <- installed.packages()[, "Package"]
  
  # Check which packages need to be installed
  packages_to_install <- packages[!packages %in% installed_packages]
  
  # Install missing packages
  if (length(packages_to_install) > 0) {
    cat("Installing missing packages:\n")
    cat(paste(" -", packages_to_install, collapse = "\n"), "\n\n")
    
    # Install packages
    install.packages(packages_to_install, 
                     repos = "https://cloud.r-project.org/",
                     dependencies = TRUE)
    
    # Verify installation
    failed_installs <- packages_to_install[!packages_to_install %in% installed.packages()[, "Package"]]
    
    if (length(failed_installs) > 0) {
      stop(paste("Failed to install the following packages:",
                 paste(failed_installs, collapse = ", "),
                 "\nPlease install them manually."))
    }
  } else {
    cat("All required packages are already installed.\n\n")
  }
}

# List of required packages
required_packages <- c(
  # Data manipulation
  "dplyr",
  "tidyverse",  # This will install dplyr, tidyr, ggplot2, stringr, etc.
  "stringr",
  "purrr",
  
  # Text processing
  "tidytext",
  "textfeatures",
  "stopwords",
  "SnowballC",
  "textstem",
  
  # Modeling
  "tidymodels",
  
  # Additional utilities
  "stringi"  # For string width calculation
)

# Check and install missing packages
cat("========================================\n")
cat("Checking for required R packages...\n")
cat("========================================\n\n")

check_and_install_packages(required_packages)

# Load required libraries
cat("\n========================================\n")
cat("Loading required R packages...\n")
cat("========================================\n\n")

# Load required libraries for data management
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyverse)
  library(stringr)
  library(purrr)
  library(tidytext)
  
  # Load libraries for text feature extraction
  library(textfeatures)
  
  # Load libraries for text processing
  library(stopwords)
  library(SnowballC)
  library(textstem)
  
  # Load libraries for modeling
  library(tidymodels)
  
  # Load utilities
  library(stringi)
})

# Set options for better display
options(scipen = 999)  # Disable scientific notation
options(digits = 4)    # Set default number of digits

# Print loaded packages and versions
cat("\nLoaded packages and versions:\n")
loaded_packages <- c("dplyr", "tidyverse", "stringr", "purrr", "tidytext", 
                    "textfeatures", "stopwords", "SnowballC", "textstem", 
                    "tidymodels", "stringi")

package_versions <- sapply(loaded_packages, function(pkg) {
  as.character(packageVersion(pkg))
})

# Create a formatted table
version_df <- data.frame(
  Package = names(package_versions),
  Version = unname(package_versions)
)

print(version_df, row.names = FALSE)

cat("\n========================================\n")
cat("IPV-Related Suicide Classifier environment is ready!\n")
cat("========================================\n")