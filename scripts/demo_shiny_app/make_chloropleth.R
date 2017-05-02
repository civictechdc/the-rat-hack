library(tidyverse)
library(lubridate)
library(leaflet)
library(rgdal)
library(sp)

#####
# Demonstration of how to make a chloropleth with summarized data
#
setwd(getSrcDirectory(function(x){}))

# created from write_importData_for_shiny_app.R 
# cols: service_code, service_code_description, time_aggregation_unit, time_aggregation_value, year, census_tract, count
data_file = "./data/dc_311-2016_summarized.csv"
summarized_data = read_csv(data_file, col_types = cols(service_code = col_character()))

census_block_data = readOGR("../../data/dc_census_block_shapefiles/census_2010/", "tl_2016_11_tabblock10")

make_chloropleth = function(summarized_data,
                            selected_service_code,
                            selected_time_aggregation_value,
                            filter_na = FALSE) {
  
  palette = colorBin(
    palette = "plasma",
    domain = summarized_data %>%
      ungroup %>%
      filter(service_code == selected_service_code) %>%
      select(count) %>%
      unlist
  )
  
  map_data = census_block_data %>%
    merge(summarized_data %>%
            filter(service_code == selected_service_code,
                   time_aggregation_value == selected_time_aggregation_value) %>%
            rename(TRACTCE10 = census_tract),
          by = "TRACTCE10")
  
  if (filter_na) {
    map_data = map_data[!is.na(map_data$count), ]
  }
  
  output_map = leaflet(map_data) %>%
    addPolygons(
      stroke = FALSE, fillOpacity = 0.7, smoothFactor = 0.5,
      color = ~palette(count),
      label = ~paste0("Tract ", substr(TRACTCE10, 3, 6),
                      ": ", count, ifelse(is.na(count) | count > 1, " requests", " request"))
    ) %>%
    setView(lng = -77.0369, lat = 38.9072, zoom = 12) %>%
    addProviderTiles("Stamen.TonerLite") %>%
    addLegend("bottomleft", pal = palette, values = ~count, title = "Requests", opacity = 1)
  
  print(output_map)
}

# make_chloropleth(summarized_data = summarized_data,
#                  selected_service_code = "S0311",
#                  selected_time_aggregation_value = 1)
# 
# make_chloropleth(summarized_data = summarized_data,
#                  selected_service_code = "S0311",
#                  selected_time_aggregation_value = 2)
# 
# make_chloropleth(summarized_data = summarized_data,
#                  selected_service_code = "S0311",
#                  selected_time_aggregation_value = 3)
# 
# make_chloropleth(summarized_data = summarized_data,
#                  selected_service_code = "S0311",
#                  selected_time_aggregation_value = 4)
# 
# make_chloropleth(summarized_data = summarized_data,
#                  selected_service_code = "S0311",
#                  selected_time_aggregation_value = 5)

make_chloropleth(summarized_data = summarized_data,
                 selected_service_code = "S0311",
                 selected_time_aggregation_value = 8)