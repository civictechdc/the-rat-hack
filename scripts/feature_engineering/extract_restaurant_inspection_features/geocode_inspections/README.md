This script is intended to provide geocoding for restaurant inspections in DC.

The script takes two command-line inputs: 
1) a file in the `potential_inspection_summary_data.csv` format as the file [here](https://github.com/jasonasher/dc_restaurant_inspections/tree/master/output)
2) the desired output file name

The output is a csv file with four columns:

`inspection_id`: The id of each inspection (one line for each)
`lon`: the longitude of the address of the establishment being inspected
`lat`: the latitude of the address of the establishment being inspected
`census_block_2010`: the 2010 census block (15-character GEOID) that contains the inspection

Missing data is represented with `NA` values. This can occur because the geocoding fails, or the census block in question is outside of DC.

Sample usage:

./geocode_inspections.R ../../../../data/dc_restaurant_inspections/potential_inspection_summary_data.csv restaurant_inspections_geocoded.csv
