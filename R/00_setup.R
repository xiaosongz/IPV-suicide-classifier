## 00_setup.R - Setup and Load Required Libraries
## IPV-Related Suicide Classifier
## Purpose: Load all required R packages and set up the environment

# Load required libraries for data management
library(dplyr)
library(tidyverse)
library(stringr)
library(tidytext)

# Load libraries for text feature extraction
library(textfeatures)

# Load libraries for text processing
library(stopwords)
library(SnowballC)
library(textstem)

# Load libraries for modeling
library(tidymodels)

# Set options for better display
options(scipen = 999)  # Disable scientific notation
options(digits = 4)    # Set default number of digits

# Print loaded packages
cat("All required packages loaded successfully.\n")
cat("IPV-Related Suicide Classifier environment is ready.\n")