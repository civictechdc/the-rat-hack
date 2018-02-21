#* @get /summarized_311_data
function(service_code, spatial_aggregation_unit = "anc") {
  spatial_aggregation_unit = tolower(spatial_aggregation_unit)
  if (! spatial_aggregation_unit %in% c("anc")){
    stop("Spatial aggregation unit is invalid - 
         only `anc` is supported")
  }
  data %>% 
    filter(SERVICECODE == service_code) %>%
    mutate(SERVICEORDERDATE_year = date_part('year', SERVICEORDERDATE),
           SERVICEORDERDATE_month = date_part('month', SERVICEORDERDATE)) %>%
    group_by(ANC, SERVICEORDERDATE_year, SERVICEORDERDATE_month) %>%
    summarize(count = n()) %>%
    collect() %>%
    ungroup %>%
    rename(anc = ANC,
           year = SERVICEORDERDATE_year,
           month = SERVICEORDERDATE_month) %>%
    arrange(year, month, anc) %>%
    complete(year, month, anc, fill = list(count = 0))
}
