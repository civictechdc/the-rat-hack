# OpenTable does not have an official API; this is an unofficial one.
opentable_url <- "http://opentable.herokuapp.com/api/restaurants/953"
ot_restaurant_response <- GET(opentable_url)

# Get parallel computing packages
library(doParallel)
registerDoParallel(cores=4) # Please set the number of processing cores or processors you have.

# Get other packages
library(dplyr)

opentable_api_data <- foreach(icount(opentable_api_mappings), .combine=rbind) %dopar% {
  opentable_url <- paste("http://opentable.herokuapp.com/api/restaurants/",)
  print(opentable_url)
}