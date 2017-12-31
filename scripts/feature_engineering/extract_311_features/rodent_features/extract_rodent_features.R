#!/usr/bin/env Rscript
library(tidyverse)
library(stringr)
library(lubridate)
library(tidytext)
library(tm)

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
  select(GEOID10) %>%
  rename(census_block_2010 = GEOID10)

rodent_data_with_block = rodent_data %>%
  bind_cols(rodent_data_spatial_block) %>%
  filter(!is.na(census_block_2010)) # Some entries have LATITUDE == 0 (e.g.) which is invalid

#####
# Add whether or not rodents were found
# This is adapted from code from Daniel Turse
#

# First - remove stop words (aside from 'no' and 'not'), digits, and punctuation
# Then - remove words related to address or attached-images
service_notes_cleaned = rodent_data_with_block %>%
  select(SERVICEREQUESTID, SERVICENOTES) %>%
  mutate(SERVICENOTES = str_to_lower(SERVICENOTES) %>%
           removeWords(stop_words %>%
                         filter(!(word %in% c("no", "not"))) %>%
                         pull(word)) %>%
           removeNumbers() %>%
           removePunctuation() %>%
           str_replace_all(c("\\bwashington\\b" = "",
                             "\\bdc\\b" = "",
                             "\\busa\\b" = "",
                             "\\bnorthwest\\b" = "",
                             "\\bnortheast\\b" = "",
                             "\\bsouthwest\\b" = "",
                             "\\bsoutheast\\b" = "",
                             "\\bnw\\b" = "",
                             "\\bne\\b" = "",
                             "\\bsw\\b" = "",
                             "\\bse\\b" = "",
                             "\\buser\\sentered\\saddress\\b" = "",
                             "\\bissue\\simage\\sview\\b" = "",
                             "\\bdetails\\svisit\\shttp\\b" = "",
                             "\\bseeclickfixcom\\sissues\\b" = "",
                             "\\s{2,}" = " "
           )))

# Next, create the regexes for each case
rodents_likely_found = function (notes_string) {
  !is.na(str_match(str_to_lower(notes_string),
                   "(a){0,1}ba(i){0,1}ted|blocks epa( ){0,1}|ditrac|( ){0,1}epa( ){0,1}|(?<!no )rat(s){0,1} burrows found|reveal rat burrows|rat burrows (n|r)ear property|soft bait")[,1])
}

rodents_likely_not_found = function (notes_string) {
  !is.na(str_match(str_to_lower(notes_string), "no rat(s){0,1}|no rodent|no action|no (active ){0,1}burrow(s){0,1}|no activity|no(t){0,1} eviden(ce){0,1}(ts){0,1}|no sign(s){0,1} rat(s){0,1}|no sign(s){0,1}|no(t){0,1} find")[,1])
}

# Finally, build the feature table
feature_table = rodent_data_with_block %>%
  select(SERVICEREQUESTID, SERVICEORDERDATE, census_block_2010) %>%
  left_join(service_notes_cleaned, by = "SERVICEREQUESTID") %>%
  mutate(found = rodents_likely_found(SERVICENOTES),
         not_found = rodents_likely_not_found(SERVICENOTES)) %>%
  mutate(feature_subtype = case_when(not_found & !found~ "rats_not_found",
                                     found & !not_found~ "rats_found",
                                     TRUE ~ "unknown"),
         feature_id = "311_service_requests",
         feature_type = "S0311",
         year = isoyear(SERVICEORDERDATE),
         week = isoweek(SERVICEORDERDATE)) %>%
  group_by(feature_id, feature_type, feature_subtype, year, week, census_block_2010) %>%
  summarize(value = n()) %>%
  arrange(year, week, census_block_2010, feature_subtype)

write_csv(feature_table, args[3])
