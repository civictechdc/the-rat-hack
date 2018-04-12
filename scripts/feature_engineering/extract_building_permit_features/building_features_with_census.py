#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pandas as pd
import geopandas.tools
from shapely.geometry import Point
import sys
import glob

source_data = sys.argv[1]
shape_file = sys.argv[2]
output_file_name = sys.argv[3]

# read in data
fields = ['ISSUE_DATE', 'PERMIT_TYPE_NAME', 'PERMIT_SUBTYPE_NAME', 'LONGITUDE', 'LATITUDE']
# df = pd.read_csv(sys.argv[1], usecols=fields)

data_frames = []
for file in glob.glob(sys.argv[1] + "/*.csv"):
    df = pd.read_csv(file, index_col=None, header=0, usecols=fields)
    data_frames.append(df)
df = pd.concat(data_frames)

# geocode lat long to census block
df['geometry'] = df.apply(lambda row: Point(row['LONGITUDE'], row['LATITUDE']), axis=1)
df = geopandas.GeoDataFrame(df, geometry='geometry')
df.crs = {'init': 'epsg:4326'}

census_blocks = geopandas.GeoDataFrame.from_file(shape_file)
census_blocks.crs = {'init': 'epsg:4326'}

result = geopandas.tools.sjoin(df[['geometry']], census_blocks[['BLOCKCE10', 'geometry']], how='left')

df['census_block_2010'] = result['BLOCKCE10']
df = df[fields + ['census_block_2010']]

# clean up, rename
del df['LONGITUDE']
del df['LATITUDE']
df = df.rename(columns={'PERMIT_TYPE_NAME': 'feature_type', 'PERMIT_SUBTYPE_NAME': 'feature_subtype'})

# adding value and feature_id field
df = df.groupby(['feature_type', 'feature_subtype', 'census_block_2010', 'ISSUE_DATE']).size()
df = df.reset_index()
df = df.rename(columns={0: 'value'})

# convert date column to date type
df['ISSUE_DATE'] = pd.to_datetime(df.ISSUE_DATE)
df.index = df['ISSUE_DATE']

# Resample to weekly and fill in blanks with zeros
WeeklyData = df.groupby(['feature_type', 'feature_subtype', 'census_block_2010']).resample('W-MON', closed='left',
                                                                                           on='ISSUE_DATE',
                                                                                           label='left').sum().reset_index()
WeeklyData.sort_values(by=['feature_type', 'feature_subtype', 'census_block_2010', 'ISSUE_DATE'])
WeeklyData = WeeklyData.fillna(0)

# Sum over rolling 4 week periods from weekly data
Avg4Week = WeeklyData.groupby(by=['feature_type', 'feature_subtype', 'census_block_2010']).rolling(4, min_periods=1,
                                                                                                   on='ISSUE_DATE').sum()

# Add integer year and weeks
Avg4Week = Avg4Week[['feature_type', 'feature_subtype', 'census_block_2010', 'ISSUE_DATE', 'value']].reset_index(
    drop=True)
Avg4Week['year'], Avg4Week['week'] = Avg4Week['ISSUE_DATE'].apply(lambda x: x.isocalendar()[0]), Avg4Week[
    'ISSUE_DATE'].apply(lambda x: x.isocalendar()[1])
Avg4Week['feature_id'] = 'building_permits_issued_last_4_weeks'
Avg4Week = Avg4Week[['feature_id', 'feature_type', 'feature_subtype', 'year', 'week', 'census_block_2010', 'value']]

# Output File to CSV
Avg4Week.to_csv(output_file_name, index=False)
