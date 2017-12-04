library(tidyverse)

setwd(getSrcDirectory(function(x){}))

non_rodent_features = read_csv("non_rodent_features.csv",
                               col_types = cols(
                                 feature_id = col_character(),
                                 feature_type = col_character(),
                                 feature_subtype = col_character(),
                                 year = col_integer(),
                                 week = col_integer(),
                                 census_block_2010 = col_character(),
                                 value = col_integer()
                               ))

column_downselected = read_csv("column_downselection.csv",
                               col_types = cols(
                                 SERVICECODE = col_character(),
                                 SERVICECODEDESCRIPTION = col_character(),
                                 n_requests = col_integer(),
                                 use = col_logical(),
                                 proposed_aggregation = col_character()
                               )) %>%
  mutate(aggregation = ifelse(is.na(proposed_aggregation), SERVICECODE, proposed_aggregation))

non_rodent_features_downselected = non_rodent_features %>%
  left_join(column_downselected %>%
              select(SERVICECODE, use, aggregation), by = c("feature_type" = "SERVICECODE")) %>%
  filter(use) %>%
  select(-feature_type) %>%
  rename(feature_type = aggregation) %>%
  group_by(feature_id, feature_type, feature_subtype, year, week, census_block_2010) %>%
  summarize(value = sum(value))

write_csv(non_rodent_features_downselected, "non_rodent_features_downselected.csv")
