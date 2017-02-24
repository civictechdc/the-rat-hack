# Let's get started. 
setwd("~/dev/side_projects/the-rat-hack/")

# Load necessary libraries.
library(dplyr)

# Read in the data
inspections_data <- read.csv("restaurant_code_violations/inspections.csv")
opentable_api_mappings <- read.csv("restaurant_code_violations/opentable_crosswalk.csv")
yelp_api_mappings <- read.csv("restaurant_code_violations/yelp_crosswalk.csv")
violations_labels <- read.csv("restaurant_code_violations/violations_key.csv")
violations_data <- read.csv("restaurant_code_violations/violations.csv")
