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
                 header = tags$head(includeScript("google_analytics.js")),
                 id="tabs",
                 tabPanel("Explore",
                          tags$style(type = "text/css", "#explore_map {height: calc(100vh - 80px) !important;}
                                     #explore_controls {opacity: 0.85; padding: 10px}
                                     #explore_controls:hover {opacity: 1.0}"), # Setting map height this way (CSS3) to fill screen in the tab panel
                          leafletOutput("explore_map", width = "100%", height = "100%"),
                          absolutePanel(id = "explore_controls", class = "panel panel-default", top = 60, right = 20,
                                        actionButton("center_explore_map", "Center map"),
                                        selectInput("explore_selected_service_code", "Service Request Type",
                                                    setNames(c(TOTAL_REQUESTS_SERVICE_CODE, service_codes_and_descriptions$service_code),
                                                             c("Total Requests", service_codes_and_descriptions$service_code_description))),
                                        checkboxInput("explore_normalize_by_total_requests", "Display as Percent of Total Requests", FALSE),
                                        sliderInput("explore_selected_time_aggregation_value", "Month",
                                                    min(summarized_data$time_aggregation_value),
                                                    max(summarized_data$time_aggregation_value),
                                                    value = min(summarized_data$time_aggregation_value),
                                                    step = 1),
                                        plotOutput("explore_request_count_time_series_plot", height = 200))
                          ),
                 tabPanel("Compare",
                          tags$style(type = "text/css",
                                    "#compare_leftmap {height: calc(100vh - 360px) !important; float: left}
                                     #compare_rightmap {height: calc(100vh - 360px) !important; float: left}
                                     #compare_controls {padding: 10px; margin:auto}"), # Setting map height this way (CSS3) to fill screen in the tab panel,
                          leafletOutput("compare_leftmap", width = "50%", height = "auto"),
                          leafletOutput("compare_rightmap", width = "50%", height = "auto"),
                          fluidRow(id = "compare_controls",
                            column(4,
                              actionButton("center_compare_maps", "Center maps"),
                              checkboxInput("single_service", "Single Service Request", FALSE),
                              checkboxInput("single_time", "Single Time Frame", FALSE),
                              conditionalPanel( condition = "input.single_service == true",
                              selectInput("compare_selected_service_code_single", "Service Request Type",
                                               setNames(c(TOTAL_REQUESTS_SERVICE_CODE, service_codes_and_descriptions$service_code),
                                                             c("Total Requests", service_codes_and_descriptions$service_code_description)))),

                              conditionalPanel( condition = "input.single_service == false",
                              selectInput("compare_selected_service_code_left", "Service Request Type (left)",
                                               setNames(c(TOTAL_REQUESTS_SERVICE_CODE, service_codes_and_descriptions$service_code),
                                                             c("Total Requests", service_codes_and_descriptions$service_code_description))),
                              selectInput("compare_selected_service_code_right", "Service Request Type (right)",
                                               setNames(c(TOTAL_REQUESTS_SERVICE_CODE, service_codes_and_descriptions$service_code),
                                                             c("Total Requests", service_codes_and_descriptions$service_code_description)))),
                               conditionalPanel( condition = "input.single_time == true",
                               sliderInput("compare_selected_time_aggregation_value_single", "Month", min(summarized_data$time_aggregation_value), max(summarized_data$time_aggregation_value), value = min(summarized_data$time_aggregation_value), step = 1)
                               ),
                               conditionalPanel( condition = "input.single_time == false",
                               sliderInput("compare_selected_time_aggregation_value_left", "Month (left)", min(summarized_data$time_aggregation_value), max(summarized_data$time_aggregation_value), value = min(summarized_data$time_aggregation_value), step = 1),
                               sliderInput("compare_selected_time_aggregation_value_right", "Month (right)", min(summarized_data$time_aggregation_value), max(summarized_data$time_aggregation_value), value = min(summarized_data$time_aggregation_value), step = 1)
                               ),


                              checkboxInput("compare_normalize_by_total_requests", "Display as Percent of Total Requests", FALSE)

                            ),
                            column(4,
                              plotOutput("compare_request_count_time_series_plot_left", height = 200, width = 300),
                              plotOutput("compare_request_count_time_series_plot_right", height = 200, width = 300)
                            )
                          )
                        ),
                   tabPanel("Description", uiOutput("description"))
                 )

server <- function(input, output, session) {

  #####
  # Helper functions
  # These are used to reduce redundant code across tabs
  #

  get_selected_service_code_data <- function(selected_service_code) {
    if (selected_service_code == TOTAL_REQUESTS_SERVICE_CODE) {
      total_request_data %>%
        mutate(count = total_requests) # Add this column to make the code below work without modification
    } else {
      summarized_data %>%
        filter(service_code == selected_service_code) %>%
        left_join(total_request_data, by = c("year", "census_tract", "time_aggregation_value")) # adds 'total_requests' column
    }
  }

  get_map_data <- function(selected_service_code_data,
                           selected_time_aggregation_value,
                           normalize_by_total_requests) {
    census_tract_data %>%
      merge(selected_service_code_data %>%
              filter(time_aggregation_value == selected_time_aggregation_value,
                     !is.na(census_tract)) %>%
              rename(TRACT = census_tract) %>%
              mutate(map_metric = if(normalize_by_total_requests){count/total_requests}else{count}),
            by = "TRACT")
  }

  get_palette <- function(selected_service_code_data,
                          normalize_by_total_requests) {
    if (nrow(selected_service_code_data) == 0) {
      domain <- c(0,1)
      bins <- 2
    } else {
      if (!normalize_by_total_requests) {
        domain <- c(0, selected_service_code_data %>%
                      filter(!is.na(census_tract)) %>%
                      select(count) %>%
                      unlist %>%
                      max)
        bins <- max(min(max(domain)-min(domain), 8), 2)
      } else {
        domain <- c(0, selected_service_code_data %>%
                      filter(!is.na(census_tract)) %>%
                      mutate(relative_count = count / total_requests) %>%
                      select(relative_count) %>%
                      unlist %>%
                      max)
        bins <- 8
      }
    }
    colorBin(palette = "plasma",
             domain = domain,
             bins = bins)
  }

  update_polygons <- function(map_id,
                              map_data,
                              palette) {
    leafletProxy(map_id, data = map_data) %>%
      addPolygons(
        stroke = TRUE,
        color = "black",
        weight = 1,
        fillColor = ~palette(map_metric),
        fillOpacity = 0.7,
        smoothFactor = 0.5,
        layerId = ~TRACT, # Using a layerId enables efficient redrawing without clearing polygons
        label = ~paste0("Tract ", substr(TRACT, 3, 6),
                        ": ", count, ifelse(is.na(count) | count != 1, " requests", " request")),
        highlightOptions = highlightOptions(color = "white", weight = 2, bringToFront = TRUE)
      )
  }

  update_legend <- function(map_id,
                            selected_service_code_data,
                            palette,
                            normalize_by_total_requests) {
    label_formatter <- function(prefix = "", suffix = "", between = " &ndash; ", digits = 3,
                                big.mark = ",", transform = identity) {
      function(type = "bin", cuts) {
        formatNum <- function(x) {
          format(round(transform(x), digits), trim = TRUE, scientific = FALSE,
                 big.mark = big.mark)
        }
        n <- length(cuts)
        if (normalize_by_total_requests) {
          cuts <- paste0(formatNum(100*cuts), "%")
          paste0(prefix, cuts[-n], between, cuts[-1])
        } else { # Given that all cuts will/should be integers, make bounds more clear
          if(max(cuts) == 1) { # cuts = c(0, 0.5, 1), so print 0 and 1
            paste0(prefix, c(0, 1), suffix)
          } else {
            paste0(prefix, formatNum(cuts[-n]),
                   ifelse(cuts[-1]-1>cuts[-n], paste0(between, formatNum(cuts[-1]-1)), ""),
                   suffix)
          }
        }
      }
    }

    leafletProxy(map_id) %>%
      clearControls() %>%
      addLegend("bottomleft", pal = palette,
                values = ifelse(normalize_by_total_requests,
                                selected_service_code_data$count/selected_service_code_data$total_requests,
                                selected_service_code_data$count),
                labFormat = label_formatter(),
                title = if(normalize_by_total_requests){"Request Percentage"}else{"Requests"}, opacity = 1)
  }

  update_request_time_series_plot <- function(selected_time_series_data,
                                              normalize_by_total_requests){
    p = ggplot(selected_time_series_data) +
      geom_bar(aes(x = as.factor(time_aggregation_value),
                   y = if(normalize_by_total_requests){count/total_requests}else{count}, fill = is_selected),
               stat = "identity", show.legend = FALSE) +
      scale_fill_manual(values = c("black", tableau_color_pal(palette = "tableau10")(1))) +
      labs(title = if(normalize_by_total_requests){"Request Percentage over Time"}else{"Service Requests over Time"}, x = "Month", y = "") +
      theme_bw(base_size = 14) +
      theme(axis.title.y = element_blank())
    if(normalize_by_total_requests){
      p + scale_y_continuous(labels = scales::percent)
    } else {
      p
    }
  }

  #####
  # 'Explore' tab
  #

  # Data for selected service code
  explore_selected_service_code_data = reactive({
    get_selected_service_code_data(input$explore_selected_service_code)
  })

  # Geographic data with the number of requests for the selected service code mapped to census tract
  explore_map_data <- reactive({
    get_map_data(explore_selected_service_code_data(),
                 input$explore_selected_time_aggregation_value,
                 input$explore_normalize_by_total_requests)
  })

  # Data for the time series chart of requests for the selected service code
  explore_time_series_data <- reactive({
    explore_selected_service_code_data() %>%
      group_by(time_aggregation_value) %>%
      summarize(count = sum(count),
                total_requests = sum(total_requests)) %>%
      mutate(is_selected = ifelse(time_aggregation_value == input$explore_selected_time_aggregation_value, TRUE, FALSE))
    })

  # Initialize map
  output$explore_map <- renderLeaflet({
    leaflet() %>%
      setView(lng = -77.0369, lat = 38.9072, zoom = 12) %>% # Center on DC
      addProviderTiles("CartoDB.PositronNoLabels")
  })

  # Color palette that is updated to match the range of values for the selected service code
  explore_palette <- reactive({
    get_palette(explore_selected_service_code_data(),
                input$explore_normalize_by_total_requests)
  })

  # Update polygons when service code or month/week is changed
  observe({
    update_polygons("explore_map",
                    explore_map_data(),
                    explore_palette())
  })

  # center map function

  observeEvent(input$center_explore_map, {
    leafletProxy("explore_map") %>%
      setView(lng = -77.0369, lat = 38.9072, zoom = 12)
  })

  # Update legend when service code is changed
  observe({
    update_legend("explore_map",
                  explore_selected_service_code_data(),
                  explore_palette(),
                  input$explore_normalize_by_total_requests)
  })

  # Update time series chart
  output$explore_request_count_time_series_plot <- renderPlot({
    update_request_time_series_plot(explore_time_series_data(),
                                    input$explore_normalize_by_total_requests)
  })



  #####
  # 'Compare' tab
  #

  # Function to center both maps
  observeEvent(input$center_compare_maps, {
    leafletProxy("compare_leftmap") %>%
      setView(lng = -77.0369, lat = 38.9072, zoom = 11)
    leafletProxy("compare_rightmap") %>%
      setView(lng = -77.0369, lat = 38.9072, zoom = 11)
  })

  #### Data for selected service code ####
  # left panel
  compare_selected_service_code_data_left = reactive({
    get_selected_service_code_data(input$compare_selected_service_code_left)
  })


  # right panel
  compare_selected_service_code_data_right = reactive({
    get_selected_service_code_data(input$compare_selected_service_code_right)
  })

  # single panel
  compare_selected_service_code_data_single = reactive({
    get_selected_service_code_data(input$compare_selected_service_code_single)
  })

  #### Geographic data with the number of requests for the selected service code mapped to census tract ####
  # left panel

  compare_map_data_left <- reactive({

    if (input$single_service==TRUE && input$single_time==TRUE){

      get_map_data(compare_selected_service_code_data_single(),
                   input$compare_selected_time_aggregation_value_single,
                   input$compare_normalize_by_total_requests)
    } else if (input$single_service==TRUE && input$single_time==FALSE){
      get_map_data(compare_selected_service_code_data_single(),
                   input$compare_selected_time_aggregation_value_left,
                   input$compare_normalize_by_total_requests)
    } else if (input$single_service==FALSE && input$single_time==TRUE){
      get_map_data(compare_selected_service_code_data_left(),
                   input$compare_selected_time_aggregation_value_single,
                   input$compare_normalize_by_total_requests)
    } else {
      get_map_data(compare_selected_service_code_data_left(),
                   input$compare_selected_time_aggregation_value_left,
                   input$compare_normalize_by_total_requests)
    }


  })

  # right panel
  compare_map_data_right <- reactive({
     if (input$single_service==TRUE && input$single_time==TRUE){

       get_map_data(compare_selected_service_code_data_single(),
                    input$compare_selected_time_aggregation_value_single,
                    input$compare_normalize_by_total_requests)
     } else if (input$single_service==TRUE && input$single_time==FALSE){
       get_map_data(compare_selected_service_code_data_single(),
                    input$compare_selected_time_aggregation_value_right,
                    input$compare_normalize_by_total_requests)
     } else if (input$single_service==FALSE && input$single_time==TRUE){
       get_map_data(compare_selected_service_code_data_right(),
                    input$compare_selected_time_aggregation_value_single,
                    input$compare_normalize_by_total_requests)
     } else {
       get_map_data(compare_selected_service_code_data_right(),
                    input$compare_selected_time_aggregation_value_right,
                    input$compare_normalize_by_total_requests)
     }
  })



  #### Data for the time series chart of requests for the selected service code ####
  # left panel
  compare_time_series_data_left <- reactive({
    if (input$single_service==TRUE && input$single_time==TRUE){

      compare_selected_service_code_data_single() %>%
        group_by(time_aggregation_value) %>%
        summarize(count = sum(count),
                  total_requests = sum(total_requests)) %>%
        mutate(is_selected = ifelse(time_aggregation_value == input$compare_selected_time_aggregation_value_single, TRUE, FALSE))
    } else if (input$single_service==TRUE && input$single_time==FALSE){
      compare_selected_service_code_data_single() %>%
        group_by(time_aggregation_value) %>%
        summarize(count = sum(count),
                  total_requests = sum(total_requests)) %>%
        mutate(is_selected = ifelse(time_aggregation_value == input$compare_selected_time_aggregation_value_left, TRUE, FALSE))
    } else if (input$single_service==FALSE && input$single_time==TRUE){
      compare_selected_service_code_data_left() %>%
        group_by(time_aggregation_value) %>%
        summarize(count = sum(count),
                  total_requests = sum(total_requests)) %>%
        mutate(is_selected = ifelse(time_aggregation_value == input$compare_selected_time_aggregation_value_single, TRUE, FALSE))
    } else {
      compare_selected_service_code_data_left() %>%
        group_by(time_aggregation_value) %>%
        summarize(count = sum(count),
                  total_requests = sum(total_requests)) %>%
        mutate(is_selected = ifelse(time_aggregation_value == input$compare_selected_time_aggregation_value_left, TRUE, FALSE))
    }
  })

  # right panel
  compare_time_series_data_right <- reactive({
      if (input$single_service==TRUE && input$single_time==TRUE){

        compare_selected_service_code_data_single() %>%
          group_by(time_aggregation_value) %>%
          summarize(count = sum(count),
                    total_requests = sum(total_requests)) %>%
          mutate(is_selected = ifelse(time_aggregation_value == input$compare_selected_time_aggregation_value_single, TRUE, FALSE))
      } else if (input$single_service==TRUE && input$single_time==FALSE){
        compare_selected_service_code_data_single() %>%
          group_by(time_aggregation_value) %>%
          summarize(count = sum(count),
                    total_requests = sum(total_requests)) %>%
          mutate(is_selected = ifelse(time_aggregation_value == input$compare_selected_time_aggregation_value_right, TRUE, FALSE))
      } else if (input$single_service==FALSE && input$single_time==TRUE){
        compare_selected_service_code_data_right() %>%
          group_by(time_aggregation_value) %>%
          summarize(count = sum(count),
                    total_requests = sum(total_requests)) %>%
          mutate(is_selected = ifelse(time_aggregation_value == input$compare_selected_time_aggregation_value_single, TRUE, FALSE))
      } else {
        compare_selected_service_code_data_right() %>%
          group_by(time_aggregation_value) %>%
          summarize(count = sum(count),
                    total_requests = sum(total_requests)) %>%
          mutate(is_selected = ifelse(time_aggregation_value == input$compare_selected_time_aggregation_value_right, TRUE, FALSE))
      }
  })

  #### Initialize maps ####
  # left panel
  output$compare_leftmap <- renderLeaflet({
    leaflet() %>%
      setView(lng = -77.0369, lat = 38.9072, zoom = 11) %>%
      addProviderTiles("CartoDB.PositronNoLabels")
  })

  # right panel
  output$compare_rightmap <- renderLeaflet({
    leaflet() %>%
      setView(lng = -77.0369, lat = 38.9072, zoom = 11) %>%
      addProviderTiles("CartoDB.PositronNoLabels")
  })

  #### Color palette that is updated to match the range of values for the selected service code ####
  # left legend
  compare_palette_left <- reactive({
    if (input$single_service==TRUE){
      get_palette(compare_selected_service_code_data_single(),
                  input$compare_normalize_by_total_requests)
    } else {
      get_palette(compare_selected_service_code_data_left(),
                  input$compare_normalize_by_total_requests)
    }
  })

  # right legend
  compare_palette_right <- reactive({
    if (input$single_service==TRUE){
      get_palette(compare_selected_service_code_data_single(),
                  input$compare_normalize_by_total_requests)
    } else {
      get_palette(compare_selected_service_code_data_right(),
                  input$compare_normalize_by_total_requests)
    }
  })

  observe({
    if (identical(input$tabs, "Compare")) {

    #### Update polygons when service code or month/week is changed ####
    # left

    update_polygons("compare_leftmap",
                    compare_map_data_left(),
                    compare_palette_left())

    # right
    update_polygons("compare_rightmap",
                    compare_map_data_right(),
                    compare_palette_right())

    #### Update legend when service code is changed ####

    update_legend("compare_leftmap",
                  compare_selected_service_code_data_left(),
                  compare_palette_left(),
                  input$compare_normalize_by_total_requests)

    update_legend("compare_rightmap",
                  compare_selected_service_code_data_right(),
                  compare_palette_right(),
                  input$compare_normalize_by_total_requests)
    }
  })


  #### Update time series chart ####
  # left
  output$compare_request_count_time_series_plot_left <- renderPlot({
    update_request_time_series_plot(compare_time_series_data_left(),
                                    input$compare_normalize_by_total_requests)
  })

  # right
  output$compare_request_count_time_series_plot_right <- renderPlot({
    update_request_time_series_plot(compare_time_series_data_right(),
                                    input$compare_normalize_by_total_requests)
  })

  #####
  # 'Description' tab
  #

  output$description <- renderUI({
    list(
    h3("The project"),
    p("Our goal is to enable the visualization and comparison of DC 311 service request data. This application, developed in R and using Shiny, visualizes all service requests from 2016."),
    h3("Who we are"),
    p("Code for DC is a group of volunteers interested in making a difference and improving the lives of the people of the District of Columbia through open data and data analysis. Founded in 2012, we are a non-partisan, non-political group of volunteer civic hackers working together to solve local issues and help people engage with the city."),
    a(href ="https://codefordc.org/index.html", "[Check us out on the Code for DC website]"),
    tags$hr(),
    h4("Maintainers"),
    p("Elizabeth Lee -- 'eclee25' at 'gmail' dot 'com'"),
    p("Jason Asher -- 'jason.m.asher' at 'gmail' dot 'com'"),
    tags$hr()
    )
  })


}

shinyApp(ui, server)
