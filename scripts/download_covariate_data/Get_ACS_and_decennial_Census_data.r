library(tidyverse)
library(tidycensus)

census_api_key("YOUR CENSUS API KEY HERE") # sign up for a key here: https://api.census.gov/data/key_signup.html

# Get population estimates at the Census block level from 2010 to 2015
# (need to use 5-year estimates at this level)
dc_bg_pop_acs <- map_df(2010:2015, function(x) {
  get_acs(variables = "B01001_001",
          state = "dc", county = "district of columbia",
          geography = "block group", endyear = x) %>%
    mutate(year = x)
    }) %>%
  rename(value = estimate)

# Toss in estimates from the 2000 Census
dc_bg_pop_census <- get_decennial(variables = "P001001",
              state = "dc", county = "district of columbia",
              geography = "block group", year = 2000) %>%
  mutate(year = 2000)

# Combine and clean up the data
dc_bg_pop <- bind_rows(dc_bg_pop_census, dc_bg_pop_acs) %>%
  select(-variable, -moe) %>%
  rename(population = value)

# write full dataset
writefiles <- map_df(c(2000, 2010:2015), function(x) {
  write_csv(dc_bg_pop %>% filter(year == x), path = paste0("population_by_census_block_", x, ".csv"))
})
