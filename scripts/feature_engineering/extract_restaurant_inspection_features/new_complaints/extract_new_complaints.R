#!/usr/bin/env Rscript
library(tidyverse)
library(lubridate)

args <- commandArgs(trailingOnly = TRUE)

# Read in the big table of inspection data from arg1 and the location information from arg 2
inspection_data <- read_csv(args[1],
                            col_types = cols(
                              .default = col_character(),
                              inspection_id = col_integer(),
                              inspection_date = col_date(format = ""),
                              inspection_time_in = col_time(format = ""),
                              inspection_time_out = col_time(format = ""),
                              license_period_start = col_date(format = ""),
                              license_period_end = col_date(format = ""),
                              risk_category = col_integer(),
                              total_violations = col_integer(),
                              critical_violations = col_integer(),
                              critical_violations_corrected_on_site = col_integer(),
                              critical_violations_repeated = col_integer(),
                              noncritical_violations = col_integer(),
                              noncritical_violations_corrected_on_site = col_integer(),
                              noncritical_violations_repeated = col_integer(),
                              inspector_badge_number = col_character()
                            ))

geocode_data <- read_csv(args[2],
                         col_types = cols(
                           inspection_id = col_integer(),
                           lon = col_double(),
                           lat = col_double(),
                           census_block_2010 = col_character()
                         )) # created using geocode_inspections script

# Build the output frame
output_data <- inspection_data %>%
  distinct %>%
  select(inspection_id,
         establishment_type,
         risk_category,
         inspection_date,
         inspection_type) %>%
  rename(feature_type = establishment_type,
         feature_subtype = risk_category) %>%
  mutate(feature_id = "restaurant_inspection_complaints",
         year = isoyear(inspection_date),
         week = isoweek(inspection_date),
         inspection_type = tolower(inspection_type)) %>%
  filter(str_detect(inspection_type, "complaint")) %>% # Filter down on only complaints
  left_join(geocode_data %>%
              select(inspection_id, census_block_2010) %>%
              distinct,
            by = "inspection_id") %>%
  group_by(feature_id, feature_type, feature_subtype,
           year, week, census_block_2010) %>%
  filter(!is.na(census_block_2010)) %>%
  summarize(value = n())
  

#Write to file using the third argument
write_csv(output_data, args[3])
