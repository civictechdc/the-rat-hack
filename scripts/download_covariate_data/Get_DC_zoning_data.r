library(tidyverse)
library(geojsonio)
library(sf)

dc_zone2016_url <- "https://opendata.arcgis.com/datasets/fd7c1d709bca4a9295b6fa5ec7d62446_32.geojson"
dc_zone1958_url <- "https://opendata.arcgis.com/datasets/7e36b5f8c97f440ab45e31dc58ea9471_12.geojson"

# What format do we want for the data -- SpatialPolygonsDataframe,
# Simple Features, a tibble, something else?

dc_zone2016_sp <- geojson_read(dc_zone2016_url, what = "sp")

dc_zone2016_sf <- st_as_sf(dc_zone2016_sp)

dc_zone2016_sp@data$id <- rownames(dc_zone2016_sp@data)
dc_zone2016_tbl <- dc_zone2016_sp %>%
  fortify() %>%
  left_join(dc_zone2016_sp@data, by = "id") %>%
  as.tbl()

# Plot 2016 district types using the tibble
ggplot(dc_zone2016_tbl) +
  geom_polygon(aes(x = long, y = lat, group = group,
                   fill = ZONE_DISTRICT))

# More specific zoning information (97 types)
head(dc_zone2016_tbl$ZONE_DESCRIPTION)
