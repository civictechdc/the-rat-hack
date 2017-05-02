library(tidyverse)
library(lubridate)

#####
# Write summarized 311 data for import into shiny app
# This script will not be in the shiny app itself
#
setwd(getSrcDirectory(function(x){}))

import_main_file = "../../data/311/clean/single_year/census_added/dc_311-2016.csv"
export_main_file = "./data/dc_311-2016_summarized.csv"
export_agg_file = "./data/dc_311-2016_totalrequests.csv"

write_importData_for_shiny_app <- function(import_file, export_file){
  data = read_csv(import_file, col_types = cols(SERVICECODE = col_character()))
  
  # add zero counts
  data2 <- data %>%
    select(SERVICECODE, SERVICEORDERDATE, CENSUS_TRACT) %>%
    mutate(time_aggregation_value = month(SERVICEORDERDATE)) %>%
    group_by(SERVICECODE, CENSUS_TRACT, time_aggregation_value) %>% 
    summarise(count = n()) %>% 
    ungroup %>%
    complete(SERVICECODE, CENSUS_TRACT, time_aggregation_value, fill = list(count = 0)) 
  
  ## final table formatting ##
  datayear <- year(data$SERVICEORDERDATE[1])
  
  # there are duplicated service code descriptions for the same servicecode
  labelsDf <- data %>% 
    distinct(SERVICECODE, SERVICECODEDESCRIPTION)
  dupLabels <- labelsDf %>% filter(duplicated(SERVICECODE)) %>% select(SERVICECODE) %>% unlist
  dupDf <- labelsDf %>% filter(SERVICECODE %in% dupLabels) %>% arrange(SERVICECODE) 
  labelsDf2 <- labelsDf %>%
    mutate(lenDescrip = nchar(SERVICECODEDESCRIPTION)) %>%
    group_by(SERVICECODE) %>%
    filter(lenDescrip == max(lenDescrip)) %>% # grab longer service code description
    summarise(SERVICECODEDESCRIPTION = first(SERVICECODEDESCRIPTION)) # one duplicate had descriptions of the same length

  # single service code datasets
  summarized_data <- data2 %>%
    mutate(year = datayear, time_aggregation_unit = "month") %>%
    full_join(labelsDf2, by = c("SERVICECODE")) %>%
    rename(service_code = SERVICECODE,
           service_code_description = SERVICECODEDESCRIPTION,
           census_tract = CENSUS_TRACT) %>%
    select(year, service_code, time_aggregation_unit, census_tract, service_code_description, time_aggregation_value, count)
  
  write_csv(summarized_data, export_file)
  return(summarized_data)
}

write_totalrequestsData_for_shiny_app <- function(import_file, export_agg_file){
  # write dataframe for shiny app, including aggregated total requests
  summarized_data <- clean_importData_for_shiny_app(import_file)
  
  totalrequests_df <- summarized_data %>%
    group_by(year, time_aggregation_value, census_tract) %>%
    summarise(totalrequests = sum(count)) 
  
  write_csv(totalrequests_df, export_agg_file)
  return(totalrequests_df)
}

out1 <- write_importData_for_shiny_app(import_main_file, export_main_file)
out2 <- write_totalrequestsData_for_shiny_app(import_file, export_agg_file)
# 4/30/17 EL
