#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Sep 26 19:46:34 2017

@author: Andrew Rawlings


"""

import pandas as pd
import numpy as np
import glob
import geopandas
import geopandas.tools
from shapely.geometry import Point
import datetime as dt
import sys

path = sys.argv[1] #r'E:\\VM\\DOHHackathon\\DC DOH Hackathon 2017\\data sets\\311 service requests' # use your path
allFiles = glob.glob(path + "/*.csv")
frame = pd.DataFrame()
list_ = []
for file_ in allFiles:
    df = pd.read_csv(file_,index_col=None, header=0)
    list_.append(df)
frame = pd.concat(list_)


frame.shape

list(frame)


frame_nonRodent = frame[frame['SERVICECODE'] != 'S0311']

frame_nonRodent.shape

frame_nonRodent['LATITUDE'].isnull().sum()

# Removing records with NULL values in lat-long - to get the census code block piece to run error-free
frame_nonRodent = frame_nonRodent[np.isfinite(frame_nonRodent['LATITUDE']) & np.isfinite(frame_nonRodent['LONGITUDE']) ]
frame_nonRodent.shape

column_names = list(frame_nonRodent.columns.values)
 
frame_nonRodent['geometry'] = frame_nonRodent.apply(lambda row: Point(row['LONGITUDE'],row['LATITUDE']), axis=1)
frame_nonRodent = geopandas.GeoDataFrame(frame_nonRodent, geometry='geometry')
frame_nonRodent.crs = {'init': 'epsg:4326'}
 

census_blocks = geopandas.GeoDataFrame.from_file(sys.argv[2])#'E:/VM/DOHHackathon/DC DOH Hackathon 2017/data sets/shapefiles and geospatial information/dc_2010_block_shapefiles/tl_2016_11_tabblock10.shp')
census_blocks.crs = {'init': 'epsg:4326'}
 
# result = geopandas.tools.sjoin(frame_nonRodent, census_blocks[['GEOID10', 'geometry']], how='inner')
result = geopandas.tools.sjoin(frame_nonRodent[['geometry']], census_blocks[['GEOID10', 'geometry']], how='left')
 
frame_nonRodent['census_block'] = result['GEOID10']
frame_nonRodent = frame_nonRodent[column_names + ['census_block']]


frame_nonRodent.shape
list(frame_nonRodent)

frame_nonRodent['SERVICEORDERDATE'] = pd.to_datetime(frame_nonRodent['SERVICEORDERDATE'])
frame_nonRodent['year'] = frame_nonRodent['SERVICEORDERDATE'].dt.year
frame_nonRodent['week'] = frame_nonRodent['SERVICEORDERDATE'].dt.week
               
df = frame_nonRodent.groupby(['SERVICECODE','census_block', 'year', 'week']).size().reset_index(name='value')

list(df)


df = df.rename(columns={'SERVICECODE': 'feature_type', 'census_block': 'census_block_2010'})
df['feature_id'] = "311_service_requests"
df['feature_subtype'] = ""
df.shape

list(df)


cols = ['feature_id', 'feature_type', 'feature_subtype', 'year', 'week','census_block_2010','value']
df = df[cols]

list(df)

df.to_csv(sys.argv[3], index=False)
