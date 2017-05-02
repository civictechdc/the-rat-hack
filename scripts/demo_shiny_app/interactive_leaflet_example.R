library(shiny)
library(leaflet)
library(RColorBrewer)
library(tidyverse)

#####
# Demonstration of how to make a chloropleth with summarized data
#
setwd(getSrcDirectory(function(x){}))

# created from write_importData_for_shiny_app.R 
# cols: service_code, service_code_description, time_aggregation_unit, time_aggregation_value, year, census_tract, count
data_file = "./data/dc_311-2016_summarized.csv"
summarized_data = read_csv(data_file, col_types = cols(service_code = col_character()))

census_block_data = readOGR("../../data/dc_census_block_shapefiles/census_2010/", "tl_2016_11_tabblock10")

service_codes_and_descriptions = summarized_data %>%
  select(service_code, service_code_description) %>%
  unique

ui <- bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(top = 10, right = 10,
                selectInput("selected_service_code", "Service Request Type",
                            setNames(service_codes_and_descriptions$service_code,
                                     service_codes_and_descriptions$service_code_description)),
                sliderInput("selected_time_aggregation_value", "Month",
                            min(summarized_data$time_aggregation_value),
                            max(summarized_data$time_aggregation_value),
                            value = min(summarized_data$time_aggregation_value), step = 1)
  )
)

server <- function(input, output, session) {
  
  palette <- reactive({
    colorBin(
      palette = "plasma",
      domain = summarized_data %>%
        ungroup %>%
        filter(service_code == input$selected_service_code) %>%
        select(count) %>%
        unlist
    )
  })
  
  map_data <- reactive({
    census_block_data %>%
      merge(summarized_data %>%
              filter(service_code == input$selected_service_code,
                     time_aggregation_value == input$selected_time_aggregation_value) %>%
              rename(TRACTCE10 = census_tract),
            by = "TRACTCE10")
  })
  
  output$map <- renderLeaflet({
    leaflet() %>%
      setView(lng = -77.0369, lat = 38.9072, zoom = 12) %>%
      addProviderTiles("Stamen.TonerLite")
  })
  
  observe({
    pal <- palette()
    
    leafletProxy("map", data = map_data()) %>%
      clearShapes() %>%
      addPolygons(
        stroke = FALSE, fillOpacity = 0.7, smoothFactor = 0.5,
        color = ~pal(count),
        label = ~paste0("Tract ", substr(TRACTCE10, 3, 6),
                        ": ", count, ifelse(is.na(count) | count > 1, " requests", " request"))
      ) %>%
      clearControls() %>%
      addLegend("bottomleft", pal = pal, values = ~count, title = "Requests", opacity = 1)
  })
  
}

shinyApp(ui, server)