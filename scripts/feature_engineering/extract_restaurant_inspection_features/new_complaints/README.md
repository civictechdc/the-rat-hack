# Restaurant New Complaint Feature Script

This script reads in restaurant inspection data from file and writes out a file containing a summary of new complaint data

## Input

The script takes 3 arguments:

1. The disk location of the inspection data csv file,
2. The disk location of the inspection census block csv file,
3. The disk location of the resulting output file

## Output

The script writes a file to disk at the location of the third argument containing standarized feature data.  This file is formatted as csv with a heading row.  User should include full name and extension in the third argument.

Sample usage:
./extract_new_complaints.R ../../../../data/dc_restaurant_inspections/potential_inspection_summary_data.csv ../../../../data/dc_restaurant_inspections/restaurant_inspections_geocoded.csv new_complaints.csv

## Notes

### File Handling

The script will fail with R error messages if input arguments are file locations that do not exist or are unavailable on the system.

### Input Summary File

The corresponding file for argument 1 is expected to be a large inspection summary table.  In order for the script to function properly, this file will at minimum need the following columns:

* establishment_type,
* risk_category,
* inspection_date,
* inspection_type

The script will fail with R error messages if any of these columns are not available.

### Input Location File

The corresponding file for argument 2 is expected to be the latitude / longitude / census block file corresponding to the inspection summary table.  The file will likely be created by other scripts operating on the address information in the inspection summary file.  This file will at minimum need the following column:

* census_block

If if is not present, the script will fail with R error messages.

### Script Function

The script will combine the columns indicated above from the summary file with the census block information from the location file.  The data will be grouped by establishment type, risk category, week, year, and census block.  A sum of complaints for each group will be calculated and added to the table.

The script requires the following R packages:

* lubridate
* dplyr
* readr
* tidyr

### Output Feature File

The output file will be written to the location of the third argument.  The output will be a .csv with the following columns:

* feature_id - Contains the string "restaurant_inspection_complaints" in all rows
* feature_type - Corresponds to establishment_type column in the input summary file
* feature_subtype - Corresponds to risk_category in the input summary file
* year - obtained from inspection_date column in the input summary file using lubridate::year
* week - obtained from inspection_date column in the input summary file using lubridate::week
* census_block_2010 - obtained from census_block column in location file
* value - The sum of complaints in this combination of establishment, risk category, year, week, and census block entries

Each row of the output will correspond to a specific combination of establishment, risk category, year, week, and block.  There should be no duplicate rows.
