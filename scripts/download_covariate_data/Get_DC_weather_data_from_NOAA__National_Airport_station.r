library(tidyverse)
library(rnoaa)
library(weathermetrics)

options(noaakey = "YOUR NOAA NCDC API KEY HERE") # request API key here: https://www.ncdc.noaa.gov/cdo-web/token

# Use weather data from National Airport
dc_station <- "USW00013743"

# Included variables (more at
# ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt):
# PRCP = Precipitation (tenths of mm)
# SNOW = Snowfall (mm)
# SNWD = Snow depth (mm)
# TAVG = Average temperature (tenths of degrees C)
# TMAX = Maximum temperature (tenths of degrees C)
# TMIN = Minimum temperature (tenths of degrees C)
weather_vars <- c("PRCP", "SNOW", "SNWD", "TAVG", "TMAX", "TMIN")

noaa_start <- "2000-01-01"
noaa_end <- "2016-12-31"

dc_weather <- meteo_tidy_ghcnd(stationid = dc_station,
                 date_min = noaa_start, date_max = noaa_end,
                 var = weather_vars)

dc_weather_freedomunits <- dc_weather %>%
  mutate(tavg = celsius.to.fahrenheit(tavg/10),
         tmax = celsius.to.fahrenheit(tmax/10),
         tmin = celsius.to.fahrenheit(tmin/10),
         prcp = metric_to_inches(prcp/10, unit.from = "mm"),
         snow = metric_to_inches(snow, unit.from = "mm"),
         snwd = metric_to_inches(snwd, unit.from = "mm"))

# write smaller datasets for hackathon
writefiles <- map_df(c(2014:2016), function(x) {
  write_csv(dc_weather %>% filter(lubridate::year(date) == x), path = paste0("dc_weather_", x, ".csv"))
})

# write full datasets
write_csv(dc_weather, "dc_weather.csv")
write_csv(dc_weather_freedomunits, "dc_weather_freedomunits.csv")
