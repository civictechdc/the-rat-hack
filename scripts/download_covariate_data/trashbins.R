library(tidyverse)
library(geojsonio)
library(sf)
library(ggmap)

dc_littercans_url <- "https://opendata.arcgis.com/datasets/4c9d7e966c0f435485fe0f47144c3258_10.geojson"

# What format do we want for the data -- SpatialPolygonsDataframe,
# Simple Features, a tibble, something else?

dc_littercans_sp <- geojson_read(dc_littercans_url, what = "sp")

dc_littercans_sf <- st_as_sf(dc_littercans_sp)

dc_littercans_sp@data$id <- rownames(dc_littercans_sp@data)

dc_littercans_tbl <- as.data.frame(dc_littercans_sp) %>%
  as.tbl() %>%
  rename(long = coords.x1,
         lat = coords.x2)

# Plot littercans using the tibble
qmplot(long, lat, data = dc_littercans_tbl,
       maptype = "toner-lite", color = I("red"))
