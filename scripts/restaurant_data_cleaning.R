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

# Bind together the violations data and labels. 
violations_detailed <- merge(violations_data,violations_labels,
                             by.x="Violation.Number",by.y="Violation.Number")

# Bind together the inspections and the detailed violations data
inspections_detailed <- merge(violations_detailed,inspections_data,
                              by.x='Inspection.ID',by.y='Inspection.ID')

# Pull in the crosswalks
inspections_with_yelp <- merge(inspections_detailed,yelp_api_mappings,
                               by.x='Permit.ID',by.y='PermitID')
inspections_with_crosswalks <- merge(inspections_with_yelp,opentable_api_mappings,
                                     by.x='Permit.ID',by.y='PermitID')