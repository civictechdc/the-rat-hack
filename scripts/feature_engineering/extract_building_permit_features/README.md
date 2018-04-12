This is a python script that will generate a feature table as described below.

When running the script, please provide the following arguments:
1. Path to the folder containing the source building permit data csv files.
2. Path to the shape file.
3. Path to the csv file where the output should be saved.

Sample usage:

python building_features_with_census.py C:\RatHackData\Data\Building-Permit-Data C:\RatHackData\ShapeFiles\tl_2016_11_tabblock10.shp output.csv

The script will return a feature data table for the number of new building permits issued in the last 4 weeks.

**Input:**
CSV files with data for each given year
A shape file

**Output:**
A CSV file with the format given below:

- 1 row for each building permit type and subtype, and each week, year, and census block
- The data set should include the following columns:

`feature_id`: The ID for the feature, in this case, "building_permits_issued_last_4_weeks"
`feature_type`: Building permit type
`feature_subtype`: Building permit subtype
`year`: The ISO-8601 year of the feature value
`week`: The ISO-8601 week number of the feature value
`census_block_2010`: The 2010 Census Block of the feature value
`value`: The value of the feature, i.e. the number of new building permits of the specified types and subtypes issued in the given census block during the previous 4 weeks starting from the year and week above.