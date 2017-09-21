library(tidyverse)
library(geojsonio)
library(sf)
library(ggmap)

# Source: http://opendata.dc.gov/datasets/metro-lines
dc_metro_url <- "https://opendata.arcgis.com/datasets/a29b9dbb2f00459db2b0c3c56faca297_106.geojson"

# SpatialLinesDataFrame or simple features data

dc_metro_sp <- geojson_read(dc_metro_url, what = "sp")
dc_metro_sf <- st_as_sf(dc_metro_sp)

# Plot Metro lines using the SpatialLinesDataFrame

dc_stamen12 <- get_map(location = c(-77.14, 38.78, -76.85, 39.00),
                       zoom = 12, maptype = "toner-lite")

ggmap(dc_stamen12) +
  geom_path(data = dc_metro_fortify,
            aes(x = long, y = lat, group = group),
            color = "red")
