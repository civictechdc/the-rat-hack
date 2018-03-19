import glob
import pandas as pd
import geopandas
import geopandas.tools
from shapely.geometry import Point
import math
import sys


def derive_census_block_from_coords(data):
    column_names = list(data.columns.values)

    print('Converting coordinates to point structures...')
    data['geometry'] = data.apply(lambda row: Point(row['LONGITUDE'], row['LATITUDE']), axis=1)
    data = geopandas.GeoDataFrame(data, geometry='geometry')
    data.crs = {'init': 'epsg:4326'}

    print('Getting census blocks...')
    census_blocks = geopandas.GeoDataFrame.from_file(sys.argv[2])
    census_blocks.crs = {'init': 'epsg:4326'}

    print('Applying spatial join...')
    result = geopandas.tools.sjoin(data[['geometry']], census_blocks[['GEOID10', 'geometry']], how='left')

    print('Adding census blocks to data frame...')
    data['census_block'] = result['GEOID10']
    data = data[column_names + ['census_block']]
    return data


def get_data_from_row(row, feature_type):
    dict = {'issue_year': row['issue_year'], 'issue_week': row['issue_week'], 'effective_year': row['effective_year'],
            'effective_week': row['effective_week'], 'expiration_year': row['expiration_year'],
            'expiration_week': row['expiration_week'], 'latitude': row['Y'], 'longitude': row['X'],
            'feature_type': feature_type, 'census_block' : row['census_block']}

    list = []
    if math.isnan(dict['issue_week']) or math.isnan(dict['issue_year']):
        return list

    for i in range(4):
        if dict['issue_week'] + i <= 52:
            week = dict['issue_week'] + i
            year = dict['issue_year']
        else:
            year = dict['issue_year'] + 1
            week = dict['issue_week'] + i - 52
        error = "Week was " + str(week) + "and original issue week was" + str(dict['issue_week'])
        assert (week <= 52), error
        list.append({'feature_id': 'construction_permits_issued_last_4_weeks', 'feature_type': dict['feature_type'],
                     'feature_subtype': '', 'year': year, 'week': week, 'census_block': dict['census_block']})

    effective_week = dict['effective_week']
    expiration_week = dict['expiration_week']
    effective_year = dict['effective_year']
    expiration_year = dict['expiration_year']
    index = effective_year * 52 + effective_week
    limit = expiration_year * 52 + expiration_week
    while index <= limit:
        current_year = math.floor(index / 52)
        current_week = (index % 52) + 1
        assert (0 < current_week <= 52)
        list.append({'feature_id': 'construction_permits_in_effect', 'feature_type': dict['feature_type'],
                     'feature_subtype': '', 'year': current_year, 'week': current_week,
                     'census_block': dict['census_block']})
        index += 1
    return list


print("Loading csv files...")
data_frames = []
for file in glob.glob(sys.argv[1] + "/*.csv"):
    df = pd.read_csv(file, index_col=None, header=0)
    data_frames.append(df)
df = pd.concat(data_frames)

print("Formatting data frame...")
df['EFFECTIVEDATE'] = pd.to_datetime(df['EFFECTIVEDATE'])
df['effective_year'] = df['EFFECTIVEDATE'].dt.year
df['effective_week'] = df['EFFECTIVEDATE'].dt.week

df['ISSUEDATE'] = pd.to_datetime(df['ISSUEDATE'])
df['issue_year'] = df['ISSUEDATE'].dt.year
df['issue_week'] = df['ISSUEDATE'].dt.week

df['EXPIRATIONDATE'] = pd.to_datetime(df['EXPIRATIONDATE'])
df['expiration_year'] = df['EXPIRATIONDATE'].dt.year
df['expiration_week'] = df['EXPIRATIONDATE'].dt.week

print("Getting census blocks...")
df = derive_census_block_from_coords(df)

print("Extracting features...")
all_rows = []
i = 0
feature_dict = {'ISFIXTURE': 'fixture', 'ISPAVING': 'paving', 'ISLANDSCAPING': 'landscaping',
                'ISPROJECTIONS': 'projections', 'ISPSRENTAL': 'psrental', 'ISEXCAVATION': 'excavation'}
for index, row in df.iterrows():
    # add features for each feature type that corresponds to this entry. Some entries will have more than one type
    # associated with them, thus resulting in multiple entries in the final table.
    for key in feature_dict.keys():
        if row[key] == 'T':
            data_from_row = get_data_from_row(row, feature_dict[key])
            all_rows.extend(data_from_row)
            i += 1
            if i % 2000 == 0:
                print("." * int(i / 2000))

    # Add an 'any' entry for each entry in the original table.
    data_from_row = get_data_from_row(row, 'any')
    all_rows.extend(data_from_row)
    i += 1
    if i % 2000 == 0:
        print("." * int(i/2000))

df = pd.DataFrame(all_rows)
df = df.groupby(df.columns.tolist()).size().reset_index().rename(columns={0:'value'})
print(df)

print('Saving data frame as csv...')
df.to_csv(sys.argv[3])
