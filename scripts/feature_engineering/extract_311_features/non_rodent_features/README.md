This is a python script that will generate a feature table as described below.

Sample usage:

./extract_non_rodent_features.py ~/Dropbox/Elizabeth\ Shared/Code_for_DC/Rats/data/311/clean/years_combined/ ~/Dropbox/Elizabeth\ Shared/Code_for_DC/Rats/data/dc_census_block_shapefiles/census_2010/tl_2016_11_tabblock10.shp non_rodent_features.csv

Here is the original issue (#8 from the Hackathon) on GitHub:

Start with the 311 Service Request data in the `/Data Sets/311 Service Requests/` folder in [Dropbox](https://www.dropbox.com/sh/a1ucls1dwytc22k/AAAd4WCuGdtm6qy3dKyoQRsoa?dl=0).
Write a script that uses this data to produce a feature data table for the number of new service requests in the past week that are not rodent-related (there is a separate issue to process rodent-related requests).

You can find the data format and examples on the `Feature Dataset Format` tab in [this document](https://docs.google.com/spreadsheets/d/1dp82BlwxMHGIiNPjfspWBkp_K1SZox0PXug8J8aOssU/edit#gid=1961157256)

The 'Rodent Inspection and Treatment' service code is `S0311`. We are interested in all other service request types for this feature.

**Input:**
CSV files with data for each given year

**Output:**
A CSV file with

- 1 row for each service code, week, year, and census block
- The dataset should include the following columns:

`feature_id`: The ID for the feature, in this case, `"311_service_requests"`
`feature_type`: The service code, found in the `SERVICECODE` column of the 311 data
`feature_subtype`: Left blank
`year`: The ISO-8601 year of the feature value, i.e. the year that the service requests were logged (from `SERVICEORDERDATE`)
`week`: The ISO-8601 week number of the feature value, i.e. the week that the service requests were logged (from `SERVICEORDERDATE`)
`census_block_2010`: The 2010 Census Block of the feature value
`value`: The value of the feature, i.e. the number of 311 service requests with the specified service code in the given census block during the week and year above.