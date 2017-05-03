library(shiny)
library(leaflet)
library(tidyverse)
library(ggthemes)
library(forcats)
library(sp)

setwd(getSrcDirectory(function(x){}))

load("./data/demo_shiny_app_data.RData")

TOTAL_REQUESTS_SERVICE_CODE <- "XXtotal_requestsXX" # Special key for artificially inserting 'Total Requests'

ui <- navbarPage(title = "DC 311 Portal",
                 tabPanel("Explore",
                          tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;}
                                     #controls {opacity: 0.85; padding: 10px}
                                     #controls:hover {opacity: 1.0}"), # Setting map height this way (CSS3) to fill screen in the tab panel
                          leafletOutput("map", width = "100%", height = "100%"),
                          absolutePanel(id = "controls", class = "panel panel-default", top = 60, right = 20,
                                        selectInput("selected_service_code", "Service Request Type",
                                                    setNames(c(TOTAL_REQUESTS_SERVICE_CODE, service_codes_and_descriptions$service_code),
                                                             c("Total Requests", service_codes_and_descriptions$service_code_description))),
                                        checkboxInput("normalize_by_total_requests", "Display as Percent of Total Requests", FALSE),
                                        sliderInput("selected_time_aggregation_value", "Month",
                                                    min(summarized_data$time_aggregation_value),
                                                    max(summarized_data$time_aggregation_value),
                                                    value = min(summarized_data$time_aggregation_value),
                                                    step = 1),
                                        plotOutput("request_count_time_series_plot", height = 200))
                          ),
                 tabPanel("Compare") #TODO: Merge Elizabeth's code
                 )

server <- function(input, output, session) {
  
  # Data for selected service code
  selected_service_code_data = reactive({
    if (input$selected_service_code == TOTAL_REQUESTS_SERVICE_CODE) {
      total_request_data %>%
        mutate(count = total_requests)
    } else {
      summarized_data %>%
        filter(service_code == input$selected_service_code) %>%
        left_join(total_request_data, by = c("year", "census_tract", "time_aggregation_value")) # adds 'total_requests' column 
    }
  })
  
  # Geographic data with the number of requests for the selected service code mapped to census tract
  map_data <- reactive({
    census_tract_data %>%
      merge(selected_service_code_data() %>%
              filter(time_aggregation_value == input$selected_time_aggregation_value,
                     !is.na(census_tract)) %>%
              rename(TRACT = census_tract) %>%
              mutate(map_metric = if(input$normalize_by_total_requests){count/total_requests}else{count}),
            by = "TRACT")
  })
  
  # Data for the time series chart of requests for the selected service code
  time_series_data <- reactive({
    selected_service_code_data() %>%
      group_by(time_aggregation_value) %>%
      summarize(count = sum(count),
                total_requests = sum(total_requests)) %>%
      mutate(is_selected = ifelse(time_aggregation_value == input$selected_time_aggregation_value, TRUE, FALSE))
    })
  
  # Initialize map
  output$map <- renderLeaflet({
    leaflet() %>%
      setView(lng = -77.0369, lat = 38.9072, zoom = 12) %>%
      #addProviderTiles("Stamen.TonerLite")
      addProviderTiles("CartoDB.PositronNoLabels")
  })
  
  # Color palette that is updated to match the range of values for the selected service code
  palette <- reactive({
 
    if (!input$normalize_by_total_requests) {
      domain <- c(0, selected_service_code_data() %>%
        filter(!is.na(census_tract)) %>%
        select(count) %>%
        unlist %>%
        max)
      bins <- min(max(domain)-min(domain), 8)
    } else {
      domain <- c(0, selected_service_code_data() %>%
        filter(!is.na(census_tract)) %>%
        mutate(relative_count = count / total_requests) %>%
        select(relative_count) %>%
        unlist %>%
        max)
      bins <- 8
    }
    colorBin(palette = "plasma",
             domain = domain,
             bins = bins)
  })
  
  # Update polygons when service code or month/week is changed
  observe({
    pal <- palette()
    
    leafletProxy("map", data = map_data()) %>%
      addPolygons(
        stroke = TRUE,
        color = "black",
        weight = 1,
        fillColor = ~pal(map_metric),
        fillOpacity = 0.7,
        smoothFactor = 0.5,
        layerId = ~TRACT, # Using a layerId enables efficient redrawing without clearing polygons
        label = ~paste0("Tract ", substr(TRACT, 3, 6),
                        ": ", count, ifelse(is.na(count) | count != 1, " requests", " request")),
        highlightOptions = highlightOptions(color = "white", weight = 2, bringToFront = TRUE)
      )
  })
  
  # Update legend when service code is changed
  observe({
    label_formatter <- function(prefix = "", suffix = "", between = " &ndash; ", digits = 3, 
                                big.mark = ",", transform = identity) {
        function(type = "bin", cuts) {
          formatNum <- function(x) {
            format(round(transform(x), digits), trim = TRUE, scientific = FALSE, 
                   big.mark = big.mark)
          }
          n <- length(cuts)
          if (input$normalize_by_total_requests) {
            cuts <- paste0(formatNum(100*cuts), "%")
            paste0(prefix, cuts[-n], between, cuts[-1])
          } else { # Given that all cuts will be integers make bounds more clear
            paste0(prefix, formatNum(cuts[-n]),
                   ifelse(cuts[-1]-1>cuts[-n], paste0(between, formatNum(cuts[-1]-1)), ""), 
                   suffix) #
          }
        }
    }
    
    leafletProxy("map") %>%
      clearControls() %>%
      addLegend("bottomleft", pal = palette(),
                values = ifelse(input$normalize_by_total_requests,
                                selected_service_code_data()$count/selected_service_code_data()$total_requests,
                                selected_service_code_data()$count),
                labFormat = label_formatter(),
                title = if(input$normalize_by_total_requests){"Request Percentage"}else{"Requests"}, opacity = 1)
  })
  
  # Update time series chart
  output$request_count_time_series_plot <- renderPlot({
    p = ggplot(time_series_data()) +
      geom_bar(aes(x = as.factor(time_aggregation_value),
                   y = if(input$normalize_by_total_requests){count/total_requests}else{count}, fill = is_selected),
               stat = "identity", show.legend = FALSE) +
      scale_fill_manual(values = c("black", tableau_color_pal(palette = "tableau10")(1))) +
      labs(title = if(input$normalize_by_total_requests){"Request Percentage over Time"}else{"Service Requests over Time"}, x = "Month", y = "") +
      theme_bw(base_size = 14)
    if(input$normalize_by_total_requests){
      p + scale_y_continuous(labels = scales::percent)
    } else {
      p
    }
  })
}

shinyApp(ui, server)