This is an R script that will generate a feature table as described below.

Sample usage:

./extract_rodent_features.R ../../../../data/311/clean/years_combined/ ../../../../data/dc_census_block_shapefiles/census_2010/tl_2016_11_tabblock10.shp rodent_features.csv

Here is the original issue (#7 from the Hackathon) on GitHub:

Start with the 311 Service Request data in the `/Data Sets/311 Service Requests/` folder in [Dropbox](https://www.dropbox.com/sh/a1ucls1dwytc22k/AAAd4WCuGdtm6qy3dKyoQRsoa?dl=0).
Write a script that uses this data to produce a feature data table for the number of new 'Rodent Inspection and Treatment' requests in the past week.

You can find the data format and examples on the `Feature Dataset Format` tab in [this document](https://docs.google.com/spreadsheets/d/1dp82BlwxMHGIiNPjfspWBkp_K1SZox0PXug8J8aOssU/edit#gid=1961157256)

The 'Rodent Inspection and Treatment' service code is `S0311`. Additionally, there is a `SERVICENOTES` field that may give additional information about the response to the given service requests. We are interested in knowing if those fields indicate that the resulting inspections actually found rodents or rodent burrows. We will code these as:
`"rats_found"`, `"rats_not_found"`, or `"unknown"` depending upon the resulting status.

**Input:**
CSV files with data for each given year

**Output:**
A CSV file with

- 1 row for each feature subtype (status of rodents found), week, year, and census block
- The dataset should include the following columns:

`feature_id`: The ID for the feature, in this case, `"311_service_requests"`
`feature_type`: The service code, in this case `"S0311"`
`feature_subtype`: The string, either `"rats_found"`, `"rats_not_found"`, or `"unknown"` that indicates the status of the requests in this feature entry
`year`: The ISO-8601 year of the feature value, i.e. the year that the service requests were logged (from `SERVICEORDERDATE`)
`week`: The ISO-8601 week number of the feature value, i.e. the week that the service requests were logged (from `SERVICEORDERDATE`)
`census_block_2010`: The 2010 Census Block of the feature value
`value`: The value of the feature, i.e. the number of 'Rodent Inspection and Treatment' requests of the specified subtypes in the given census block during the week and year above.