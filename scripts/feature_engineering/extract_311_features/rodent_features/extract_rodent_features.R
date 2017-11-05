#!/usr/bin/env Rscript
library(tidyverse)
library(stringr)
library(lubridate)

args = commandArgs(trailingOnly=TRUE)

#####
# Load the data
#
data_folder = args[1]
data_files = list.files(data_folder, pattern = "csv", full.names = TRUE)
data = lapply(data_files, read_csv) %>%
  bind_rows

# Filter to rodent abatement requests, and only requests with lat/long
rodent_data = data %>%
  filter(SERVICECODE == "S0311", !is.na(LATITUDE), !is.na(LONGITUDE))

#####
# Map the lat/lon to census block
#
census_block_data = raster::shapefile(args[2])
census_block_data = sp::spTransform(census_block_data, CRSobj=sp::CRS("+proj=longlat +datum=WGS84"))

rodent_data_spatial = sp::SpatialPointsDataFrame(coords = rodent_data[, c("LONGITUDE", "LATITUDE")],
                                                 data = rodent_data,
                                                 proj4string=sp::CRS("+proj=longlat +datum=WGS84"))
rodent_data_spatial_block = sp::over(x = rodent_data_spatial, y = census_block_data) %>%
  select(BLOCKCE10) %>%
  rename(census_block_2010 = BLOCKCE10)

rodent_data_with_block = rodent_data %>% bind_cols(rodent_data_spatial_block)

#####
# Add whether or not rodents were found
# Note - this is really crude at the moment, and will be improved in a future version
#

rodents_likely_found = function (notes_string) {
  !is.na(str_match(str_to_lower(notes_string),
                   "((baited|found) *([\\d]*|one|two|three|four|five|six|seven|eight|nine|ten) *(rat|burrow))|( baited )")[,1])
}

rodents_likely_not_found = function (notes_string) {
  !is.na(str_match(str_to_lower(notes_string), "found no (rat|activity|rodent|evidence)")[,1])
}

feature_table = rodent_data_with_block %>%
  select(SERVICEORDERDATE, SERVICENOTES, census_block_2010) %>%
  mutate(found = rodents_likely_found(SERVICENOTES),
         not_found = rodents_likely_not_found(SERVICENOTES)) %>%
  mutate(feature_subtype = case_when(not_found ~ "rats_not_found",
                                     found ~ "rats_found",
                                     TRUE ~ "unknown"),
         feature_id = "311_service_requests",
         feature_type = "S0311",
         year = year(SERVICEORDERDATE),
         week = week(SERVICEORDERDATE)) %>%
  group_by(feature_id, feature_type, feature_subtype, year, week, census_block_2010) %>%
  summarize(value = n()) %>%
  arrange(year, week, census_block_2010, feature_subtype)

write_csv(feature_table, args[3])