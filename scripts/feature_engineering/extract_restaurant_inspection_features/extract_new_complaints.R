require(lubridate)
require(dplyr)
require(readr)
require(magrittr)
require(tibble)
require(tidyr)

args <- commandArgs(trailingOnly = TRUE)

#Read in the big table of inspection data from arg1 and the location information from arg 2
inspections <- read_csv(args[1])
location <- read_csv(args[2]) # created using add_census_block_data.R from DropBox

#Begin building up the output frame
outputData <- data_frame(feature_type = inspections$establishment_type,
                         feature_subtype = inspections$risk_category,
                         year = year(inspections$inspection_date),
                         week = week(inspections$inspection_date),
                         census_block_2010 = location$census_block,
                         inspection_type = tolower(inspections$inspection_type))

#filter down on only complaints, group and count
outputData %<>% filter(inspection_type == "complaint") %>% 
  group_by(feature_type,feature_subtype,year,week,census_block_2010) %>% 
  summarise(value=n())

#Remove the complaint text, add our feature id, and remove rows with NA's
outputData %<>% mutate(feature_id = "restaurant_inspection_complaints", inspection_type = NULL) %>% drop_na()

#this is merely to reorder so that columns line up as suggested in the issue
outputData %<>% select(feature_id,feature_type,feature_subtype,year,week,census_block_2010,value)

#Write to file using the third argument
write_csv(outputData, args[3])