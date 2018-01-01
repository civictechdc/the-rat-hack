#!/usr/bin/env Rscript
library(tidyverse)
library(ggmap)
library(tigris)
library(sf)

args = commandArgs(trailingOnly=TRUE)

# Load the data
inspection_summary_data = read_csv(args[1],
                                   col_types = cols(
                                     .default = col_character(),
                                     inspection_id = col_integer(),
                                     inspection_date = col_date(format = ""),
                                     inspection_time_in = col_time(format = ""),
                                     inspection_time_out = col_time(format = ""),
                                     license_period_start = col_date(format = ""),
                                     license_period_end = col_date(format = ""),
                                     risk_category = col_double(),
                                     total_violations = col_integer(),
                                     critical_violations = col_double(),
                                     critical_violations_corrected_on_site = col_double(),
                                     critical_violations_repeated = col_double(),
                                     noncritical_violations = col_double(),
                                     noncritical_violations_corrected_on_site = col_double(),
                                     noncritical_violations_repeated = col_double(),
                                     inspector_badge_number = col_character()
                                   ))

# Download census block polygons
options(tigris_class = "sf")
census_block_data = tigris::blocks("DC", year = 2010) %>%
  st_transform(crs = 4326)

#####
# Geocode - map address to lat-long

# Processes up to 1K addresses using the MAR (DC only)
get_mar_geocode = function(addresses) {
  r = httr::POST("http://citizenatlas.dc.gov/newwebservices/locationverifier.asmx/findLocationBatch2",
                 body = list(addr_base64 = RCurl::base64(paste("!", do.call("paste", c(sep = " $ ", as.list(addresses)))))[1],
                             addr_separator = "$",
                             chunkSequnce_separator = "!",
                             f = "json"), encode = "json")
  content = (httr::content(r, "text") %>% jsonlite::fromJSON())
  mar_output = content[-1] %>%
    lapply(
      function(x) {
        returnDataset = x$returnDataset
        if (!is.null(returnDataset)) {
          returnDataset$Table1 %>%
            as_tibble() %>%
            filter(1:n() == 1) %>%
            select(LONGITUDE, LATITUDE) %>%
            rename(lon = LONGITUDE, lat = LATITUDE)
        } else {
          data_frame(lon = NA_real_, lat = NA_real_)
        }
      }
    ) %>%
    bind_rows
  return(mar_output)
}

get_geocode = function(addresses, GEOCODE_CACHE_LOCATION = "geocode_cache/cache.RData") {
  # Load cache - geocode cache maps address string to c(lon, lat)
  if (file.exists(GEOCODE_CACHE_LOCATION)) {
    load(GEOCODE_CACHE_LOCATION)
  } else {
    geocode_cache = data_frame(address = character(0),
                               lon = numeric(0),
                               lat = numeric(0),
                               source = character(0))
  }
  
  # First, check if addresses are in the cache
  cached_indices = which(str_to_lower(addresses) %in% geocode_cache$address)
  addresses_to_lookup = if (length(cached_indices) > 0 ) {
    addresses[-cached_indices] %>% str_to_lower %>% unique
  } else {
    addresses %>% str_to_lower %>% unique
  }
  
  # Use MAR first (as it is best for DC addresses)
  CHUNK_SIZE = 1000
  PAUSE_TIME = 2 #Seconds
  addresses_to_lookup_chunks = split(addresses_to_lookup, ceiling(seq_along(addresses_to_lookup)/CHUNK_SIZE))
  chunk_results = lapply(addresses_to_lookup_chunks,
         function(x) {
           Sys.sleep(PAUSE_TIME)
           geocode_mar_result = data_frame(address = x) %>%
             bind_cols(get_mar_geocode(x))
           geocode_cache <<- bind_rows(geocode_cache,
                                       geocode_mar_result %>%
                                        mutate(source = "MAR") %>%
                                         filter(!is.na(lon)) %>%
                                         distinct) %>%
                              distinct
           save(geocode_cache, file = GEOCODE_CACHE_LOCATION)
           return(geocode_mar_result)
          })
  mar_results = bind_rows(chunk_results)
  
  # After that, use Google assuming the number of missing addresses is small (could run into query limit)
  MAX_GOOGLE_REQUESTS = 10
  PAUSE_TIME = 0.2 #Seconds
  if (nrow(mar_results) > 0) {
    addresses_to_lookup_google =
      mar_results %>%
      filter(is.na(lon)) %>%
      pull(address)
    addresses_to_lookup_google_chunks = split(addresses_to_lookup_google,
                                              ceiling(seq_along(addresses_to_lookup_google) / MAX_GOOGLE_REQUESTS))
    chunk_results_google = lapply(addresses_to_lookup_google_chunks,
                                  function(x) {
                                    Sys.sleep(PAUSE_TIME)
                                    google_results = data_frame(address = x) %>%
                                      bind_cols(ggmap::geocode(x))
                                    geocode_cache <<- bind_rows(geocode_cache,
                                                              google_results %>%
                                                                mutate(source = "Google") %>%
                                                                filter(!is.na(lon)) %>%
                                                                distinct) %>%
                                      distinct
                                    save(geocode_cache, file = GEOCODE_CACHE_LOCATION)
                                  })
  }
  
  return(data_frame(address = str_to_lower(addresses)) %>%
           left_join(geocode_cache %>% select(-source),
                     by = "address") %>%
           select(-address))
}

output_data = inspection_summary_data %>%
  select(inspection_id, address) %>%
  do(bind_cols(data_frame(inspection_id = .$inspection_id), get_geocode(.$address)))

####
# Add census block data (only for DC)

# Get census blocks
inspection_sf_data = output_data %>%
  filter(!is.na(lat)) %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326)

intersection_data = st_intersects(inspection_sf_data, census_block_data)
# When the point is on the boundary of multiple census blocks, we take the first in the list (TODO: Is there a better option?)
mapped_census_blocks = (census_block_data$GEOID10)[intersection_data %>% 
                                                     lapply(function(x){ifelse(length(x) > 0, x[1], NA)}) %>% 
                                                     unlist]

output_data = output_data %>%
  left_join(inspection_sf_data %>%
              mutate(census_block_2010 = mapped_census_blocks) %>%
              st_set_geometry(NULL),
            by = "inspection_id")

write_csv(output_data, args[2])
