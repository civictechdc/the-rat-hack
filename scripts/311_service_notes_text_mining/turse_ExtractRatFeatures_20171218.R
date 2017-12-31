


##  This .R script uses regex functions to extract features from the raw 311 dataset. A bit of
##  pre-processing is done to clean the data before applying the regex functions. The regex
##  functions themselves were informed by previous analyses utilizing LDA for topic modeling.



######################
##  Load Libraries  ##
######################

# rm(list = ls())

library("tidyverse")          # data manipulation
library("magrittr")           # data manipulation (pipeing data)
library("lubridate")          # date manipulation
library("tidytext")           # text manipulation
library("rgdal")              # working with shapefiles



####################
##  Session Info  ##
####################

sessionInfo()

wd <- getwd()



#######################
##  Obtain Raw Data  ##
#######################

# rats data
Raw311Data <- read_csv(paste0(wd,
                              "/scripts/rats_results_of_inspection/Data_Raw/dc_311-2017-10-07.csv"
                              ),
                       progress = TRUE
                       )

glimpse(Raw311Data)


# shapefile data
RawShapefile <- readOGR(dsn = paste0(wd,
                                     "/scripts/rats_results_of_inspection/Data_Raw/dc_2010_block_shapefiles/"
                                     ),
                        layer = "tl_2016_11_tabblock10",
                        verbose = TRUE
                        )

summary(RawShapefile)



###############################
##  Data Munging to Obtain   ##
##  Final Dataset for Regex  ##
###############################

# manipulate rats
names(Raw311Data) <- tolower(names(Raw311Data))

RatCalls_Time <- Raw311Data %>% 
  filter(servicecode == "S0311" &  # rats code
           latitude > 0 &  # ensures mapping shapefile
           longitude < 0   # ensures mapping to shapefile
         ) %>% 
  select(servicerequestid,
         servicecode,
         serviceorderdate,
         inspectiondate,
         servicenotes,
         latitude,
         longitude
         ) %>% 
  mutate(serviceorder_yr_iso = isoyear(serviceorderdate),
         serviceorder_wk_iso = isoweek(serviceorderdate)
         )

glimpse(RatCalls_Time)


# manipulate shapefile
str(RawShapefile@data)
ShapeFile_Spatial <-
  spTransform(x = RawShapefile,
              CRSobj = CRS("+proj=longlat +datum=WGS84")
              )

summary(ShapeFile_Spatial)


Rats_Spatial <- 
  SpatialPointsDataFrame(coords = RatCalls_Time[ , c("longitude","latitude")],
                         data = RatCalls_Time,
                         proj4string = CRS("+proj=longlat +datum=WGS84")
                         )

summary(Rats_Spatial)

Rats_CensusBlock <- over(x = Rats_Spatial,
                         y = ShapeFile_Spatial
                         ) %>% 
  select(GEOID10) %>% 
  rename(census_block_2010 = GEOID10)

glimpse(Rats_CensusBlock)


RatCalls_CensusBlock <- bind_cols(RatCalls_Time,
                                  Rats_CensusBlock
                                  )

glimpse(RatCalls_CensusBlock)
rm(Raw311Data, RatCalls_Time, Rats_CensusBlock, Rats_Spatial, RawShapefile, ShapeFile_Spatial)



#########################################
##  Cleaning the `servicenotes` Field  ##
#########################################

# First, remove stopwords
NoStopWords_Unnest <- 
  RatCalls_CensusBlock %>% 
  select(servicerequestid,
         servicenotes
         ) %>% 
  unnest_tokens(word,
                servicenotes
                ) %>% 
  anti_join(filter(stop_words,
                   word != "no" &
                     word != "not" #  we don't remove the words "no" or "not" as they are 
                                   #  often used to distinguish between "rats found" and
                                   #  "no rats found", or "find" and "not find"
                   ),
            by = "word"
            )


Servicenotes_NoStopWrds <- NoStopWords_Unnest %>% 
  nest(word) %>% 
  mutate(servicenotes_nostop = map(data,
                                   unlist
                                   ),
         servicenotes_nostop = map_chr(servicenotes_nostop,
                                       paste,
                                       collapse = " "
                                       )
         ) %>% 
  select(-data)


# now remove digits and punctuation
Servicenotes_NoNumsNoPunc <- RatCalls_CensusBlock %>% 
  left_join(Servicenotes_NoStopWrds,
            by = "servicerequestid"
            ) %>% 
  mutate(servicenotes_nonums_nopunc = str_replace_all(servicenotes_nostop,
                                                      "[[:digit:]]",
                                                      ""
                                                      ) %>% 
           str_replace_all("[[:punct:]]",
                           ""
                           )
         ) %>% 
  select(-servicenotes_nostop)


# now remove words related to address or attached-images
fix_list <- c("\\bwashington\\b" = "",
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
)


ServiceNotesCleaned <- Servicenotes_NoNumsNoPunc %>% 
  mutate(servicenotes_cleaned = str_replace_all(servicenotes_nonums_nopunc,
                                                fix_list
                                                )
         )

dim(RatCalls_CensusBlock)
dim(ServiceNotesCleaned)
glimpse(ServiceNotesCleaned)
rm(RatCalls_CensusBlock, NoStopWords_Unnest, Servicenotes_NoNumsNoPunc, Servicenotes_NoStopWrds,
   fix_list
   )



##############################
##  Create the Regex Model  ##
##############################

regex_ratsfound <- "(a){0,1}ba(i){0,1}ted|blocks epa( ){0,1}|ditrac|( ){0,1}epa( ){0,1}|(?<!no )rat(s){0,1} burrows found|reveal rat burrows|rat burrows (n|r)ear property|soft bait"

regex_noratsfound <- "no rat(s){0,1}|no rodent|no action|no (active ){0,1}burrow(s){0,1}|no activity|no(t){0,1} eviden(ce){0,1}(ts){0,1}|no sign(s){0,1} rat(s){0,1}|no sign(s){0,1}|no(t){0,1} find"



Regex_Model <- ServiceNotesCleaned %>% 
  mutate(snc_ratsfound = str_detect(servicenotes_cleaned,
                                    regex_ratsfound
                                    ),
         snc_noratsfound = str_detect(servicenotes_cleaned,
                                        regex_noratsfound
                                        ),
         snc_outcome = case_when(snc_ratsfound == TRUE &
                                   snc_noratsfound == FALSE ~ "rats_found",
                                 snc_ratsfound == FALSE &
                                   snc_noratsfound == TRUE ~ "rats_not_found",
                                 TRUE ~ "unknown"
                                 )
         )

dim(ServiceNotesCleaned)
dim(Regex_Model)
glimpse(Regex_Model)

# View(Regex_Model %>% 
#        filter(snc_outcome == "rats_found") %>% 
#        sample_n(5) %>% 
#        bind_rows(Regex_Model %>% 
#                    filter(snc_outcome == "rats_not_found") %>% 
#                    sample_n(5)
#                  ) %>% 
#        bind_rows(Regex_Model %>% 
#                    filter(snc_outcome == "unknown") %>% 
#                    sample_n(5)
#                  ) %>% 
#        arrange(snc_outcome) %>% 
#        select(servicenotes,
#               servicenotes_cleaned,
#               snc_outcome
#               )
#      )

rm(ServiceNotesCleaned, regex_noratsfound, regex_ratsfound)



#########################
##  Create the Counts  ##
#########################

RatFeatures_Results <- Regex_Model %>% 
  mutate(feature_id = "311_service_requests") %>% 
  rename(feature_type = servicecode,
         feature_subtype = snc_outcome,
         year = serviceorder_yr_iso,
         week = serviceorder_wk_iso
         ) %>% 
  group_by(feature_id,
           feature_type,
           feature_subtype,
           year,
           week,
           census_block_2010
           ) %>% 
  summarise(value = n()
            ) %>% 
  arrange(year,
          week,
          census_block_2010,
          feature_subtype
          )

glimpse(RatFeatures_Results)
View(RatFeatures_Results)


write_csv(x = RatFeatures_Results,
          path = paste0(wd,
                        "/scripts/rats_results_of_inspection/Data_Processed/RatFeatures_Results.csv"
                        )
          )



