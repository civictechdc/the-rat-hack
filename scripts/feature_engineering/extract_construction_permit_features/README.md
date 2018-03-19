This is a python script that will generate a feature table as described below.

Sample usage:

./extract_features_from_construction_permit_data.py ../../../../Rats/data/311/clean/2014-2016_construction_permit_data/ ../../../../data/dc_census_block_shapefiles/census_2010/tl_2016_11_tabblock10.shp construction_permit_features.csv

Here is the original issue (#12) on GitHub:

Start with the Construction Permit data in the /Data Sets/Construction Permits/ folder in [Dropbox](https://www.dropbox.com/sh/a1ucls1dwytc22k/AAAd4WCuGdtm6qy3dKyoQRsoa?dl=0).

Write a script that uses this data to produce a feature data table for

The number of new construction permits issued in the last 4 weeks; and
The number of construction permits in effect in each week.
You can find the data format and examples on the Feature Dataset Format tab in this document

Construction permits can have one or more types, among "excavation", "fixture", "paving", "landscaping", "projections", and "psrental:. These are delineated by columns 5-10 in the permit dataset. We will counts permits (potentially more than once) by these 6 classes as well as in total with the type key "any".

**Input:**
CSV files with data for each given year

**Output:**
A script that produces a CSV file with the below format:

- 1 row for each feature id, construction permit type and subtype, and each week, year, and census block
- The dataset should include the following columns:

'feature_id': The ID for the feature, in this case, "construction_permits_issued_last_4_weeks" or "construction_permits_in_effect"
'feature_type': Construction permit type as described above, with values in "excavation", "fixture", "paving", "landscaping", "projections", "psrental" or "any".
'feature_subtype': Left blank
'year': The ISO-8601 year of the feature value
'week': The ISO-8601 week number of the feature value
'census_block_2010': The 2010 Census Block of the feature value
'value': The value of the feature, i.e. the number of construction permits of the specified type either new in the previous 4 weeks or active during the week and year in question in the given census block.