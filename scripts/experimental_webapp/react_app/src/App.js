import React, { PureComponent } from 'react';
import { Map as LeafletMap, TileLayer, GeoJSON } from 'react-leaflet';
import Slider from 'react-rangeslider';
import 'react-rangeslider/lib/index.css'
import './App.css';

class App extends PureComponent {

  state = {polygons: [],
           data: [],
           yearRange: [1999, 2017],
           getDataValues: (year, month, anc) => null,
           year: 2016,
           month: 3};

  async componentDidMount() {
    try {
      let ANCPolygons = await fetch('https://opendata.arcgis.com/datasets/fcfbf29074e549d8aff9b9c708179291_1.geojson');
      let ANCPolygonsJSON = await ANCPolygons.json();

      let data = await fetch('http://localhost:8000/summarized_311_data?service_code=S0311&spatial_aggregation_unit=anc');
      let dataJSON = await data.json();

      let dataValuesMap = new Map();
      let minYear = 2016, maxYear = 2016;
      dataJSON.forEach(row => {
        minYear = Math.min(minYear, row.year);
        maxYear = Math.max(maxYear, row.year);
        let key = [row.year, row.month, row.anc].join(',');
        dataValuesMap.set(key, row.count);
      });
      let getDataValues = (year, month, anc) => dataValuesMap.get([year, month, anc].join(','));

      this.setState({polygons: ANCPolygonsJSON, data: dataJSON,
        getDataValues: getDataValues, yearRange: [minYear, maxYear]});
    } catch(error) {
      console.error(error);
    }
  }

  render() {

    const mapConfig = {
      center: [38.9072, -77.0369],
      zoom: 12
    };

    const getColor = function(x) {
      return x > 50  ? '#800026' :
             x > 20  ? '#BD0026' :
             x > 10  ? '#E31A1C' :
             x > 5   ? '#FC4E2A' :
             x > 2   ? '#FD8D3C' :
             x > 1   ? '#FEB24C' :
             x > 0   ? '#FED976' :
                       '#FFEDA0'
    };

    const getDataValues = anc => this.state.getDataValues(this.state.year, this.state.month, anc)

    return (
      <div>
        <div className="map">
          <LeafletMap center={mapConfig.center} zoom={mapConfig.zoom} className="map__reactleaflet">
{/*            <TileLayer
              url='https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png'
              attribution='&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>, &copy; <a href="https://carto.com/attribution">CARTO</a>'
            />*/}
            <TileLayer
              url='https://api.tiles.mapbox.com/v4/mapbox.streets/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiamFzb25hc2hlciIsImEiOiJjajg5MHVpOTMxbjdyMzNvNm1nd2pmYWFyIn0.uzo7KIN-3521g6A0BO-mww'
              attribution='Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, 
              &copy; <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://mapbox.com">Mapbox</a>'
            />
            <GeoJSON
              key={this.state.polygons}
              data={this.state.polygons}
              style={feature => {
                let dataValue = getDataValues(feature.properties.ANC_ID);
                //console.log(feature.properties.ANC_ID, dataValue);
                return ({
                  color: getColor(dataValue),
                  weight: 2,
                  fillOpacity: 0.65
                });
              }}
              onEachFeature={(feature, layer) => {
                if (feature.properties && feature.properties.ANC_ID) {
                  let anc = feature.properties.ANC_ID;
                  let requests = getDataValues(anc);
                  layer.bindTooltip("ANC " + anc + "<br>" + requests + " request" + (requests === 1 ? "" : "s"),
                    {sticky: true, direction: 'left'});
                }
              }}
            />
          </LeafletMap>
        </div>
        <div style={{height: 200, width:1000}}>
          <div className="slider-horizontal" style={{height: 100, width:900, margin:50}}>
            <Slider min={1} max={12 * (this.state.yearRange[1] - this.state.yearRange[0] + 1)}
              value={12 * (this.state.year - this.state.yearRange[0]) + this.state.month}
              onChange={(value) => this.setState({month: (value - 1) % 12 + 1, year: 1999 + Math.floor((value - 1) / 12) })}
            />
          </div>
        </div>
      </div>
    );
  }
}

export default App;
