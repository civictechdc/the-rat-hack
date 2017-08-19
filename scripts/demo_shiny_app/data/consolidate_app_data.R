library(tidyverse)

setwd(getSrcDirectory(function(x){}))

# Loads the three ANC, Ward, and Census Tract datasets and consolidates them for use in the app

#####
# ANC
load("demo_shiny_app_data_anc.RData")

summarized_data = summarized_data %>% 
  mutate(spatial_aggregation_unit = "anc") %>%
  rename(spatial_aggregation_value = anc)

total_request_data = total_request_data %>% 
  mutate(spatial_aggregation_unit = "anc") %>%
  rename(spatial_aggregation_value = anc)

app_data = list(
  anc = list(summarized_data = summarized_data,
             total_request_data = total_request_data,
             spatial_polygon_data = adminUnit_data,
             spatial_unit_column_name = "ANC_ID",
             spatial_unit_name = "ANC")
)

#####
# Census Tract
load("demo_shiny_app_data_census_tract.RData")

summarized_data = summarized_data %>% 
  mutate(spatial_aggregation_unit = "census_tract") %>%
  rename(spatial_aggregation_value = census_tract)

total_request_data = total_request_data %>% 
  mutate(spatial_aggregation_unit = "census_tract") %>%
  rename(spatial_aggregation_value = census_tract)

app_data$census_tract = list(summarized_data = summarized_data,
                             total_request_data = total_request_data,
                             spatial_polygon_data = census_tract_data,
                             spatial_unit_column_name = "TRACT",
                             spatial_unit_name = "Census Tract")

#####
# Ward
load("demo_shiny_app_data_ward.RData")

summarized_data = summarized_data %>% 
  mutate(spatial_aggregation_unit = "ward") %>%
  rename(spatial_aggregation_value = ward)

total_request_data = total_request_data %>% 
  mutate(spatial_aggregation_unit = "ward") %>%
  rename(spatial_aggregation_value = ward)

app_data$ward = list(summarized_data = summarized_data,
                     total_request_data = total_request_data,
                     spatial_polygon_data = adminUnit_data,
                     spatial_unit_column_name = "WARD_ID",
                     spatial_unit_name = "Ward")

save(app_data, service_codes_and_descriptions, file = "app_data.RData")