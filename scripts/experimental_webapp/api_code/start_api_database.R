library(plumber)
library(tidyverse)

setwd(getSrcDirectory(function(x){}))

# this is the name of the table in the local psql DB
PACKAGE_ID = "dc_311_data"
database = DBI::dbConnect(RPostgreSQL::PostgreSQL(), dbname = "jasonasher")
data = tbl(database, PACKAGE_ID)

api = plumb("api_database.R")
api$run(port=8000)

# http://localhost:8000/service_codes_and_descriptions
# http://localhost:8000/summarized_311_data?service_code=S0311&spatial_aggregation_unit=anc