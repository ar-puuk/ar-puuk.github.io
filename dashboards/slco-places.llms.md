``` js
maplibregl = require("maplibre-gl@4.7.1")
db = DuckDBClient.of({
  places: FileAttachment("../posts/overture-data-download/output/slco_places_r.parquet")
})
places = db.sql`
  SELECT names.primary AS name,
         categories.main AS category,
         bbox.xmin AS lon,
         bbox.ymin AS lat,
         confidence,
         addresses[1].locality AS city
  FROM places
  WHERE names.primary IS NOT NULL AND categories.main IS NOT NULL
`
label = c => c.replaceAll("_", " ").replace(/^./, s => s.toUpperCase())
categoryCounts = d3.rollups(places, v => v.length, d => d.category).sort((a, b) => b[1] - a[1])
topCategories = categoryCounts.slice(0, 10).map(d => d[0])
palette = ["#007EA7", "#D96E34", "#6A4C93", "#2A9D8F", "#E9B44C", "#C44569", "#4A6FA5", "#8A9A5B", "#A23E02", "#6C757D"]
color = d3.scaleOrdinal(topCategories, palette)
```

Places selected

``` js
html`${rows.length.toLocaleString()}`
```

Share of all places

``` js
html`${(rows.length / places.length * 100).toFixed(1)}%`
```

Cities with a match

``` js
knownCities.length
```

Busiest city

``` js
html`${knownCities.length ? knownCities[0][0] : "none"}`
```

Where the selected places are

``` js
mapEl = html`<div class="map-fill"></div>`
```

Expand ![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdib3g9IjAgMCAyNCAyNCIgc3R5bGU9ImhlaWdodDoxZW07d2lkdGg6MWVtOyIgYXJpYS1oaWRkZW49InRydWUiIHJvbGU9ImltZyI+PHBhdGggZD0iTTIwIDVDMjAgNC40IDE5LjYgNCAxOSA0SDEzQzEyLjQgNCAxMiAzLjYgMTIgM0MxMiAyLjQgMTIuNCAyIDEzIDJIMjFDMjEuNiAyIDIyIDIuNCAyMiAzVjExQzIyIDExLjYgMjEuNiAxMiAyMSAxMkMyMC40IDEyIDIwIDExLjYgMjAgMTFWNVpNNCAxOUM0IDE5LjYgNC40IDIwIDUgMjBIMTFDMTEuNiAyMCAxMiAyMC40IDEyIDIxQzEyIDIxLjYgMTEuNiAyMiAxMSAyMkgzQzIuNCAyMiAyIDIxLjYgMiAyMVYxM0MyIDEyLjQgMi40IDEyIDMgMTJDMy42IDEyIDQgMTIuNCA0IDEzVjE5WiIgLz48L3N2Zz4=)

``` js
map = {
  const m = new maplibregl.Map({
    container: mapEl,
    style: "https://tiles.openfreemap.org/styles/positron",
    bounds: [[-112.26, 40.41], [-111.55, 40.93]],
    fitBoundsOptions: {padding: 20},
    attributionControl: false
  });
  m.addControl(new maplibregl.AttributionControl({compact: true, customAttribution: "Places: Overture Maps"}));
  m.addControl(new maplibregl.NavigationControl({showCompass: false}), "top-right");
  new ResizeObserver(() => m.resize()).observe(mapEl);
  await new Promise(resolve => m.on("load", resolve));
  m.addSource("places", {type: "geojson", data: {type: "FeatureCollection", features: []}});
  m.addLayer({
    id: "places",
    type: "circle",
    source: "places",
    paint: {
      "circle-color": ["get", "color"],
      "circle-radius": ["interpolate", ["linear"], ["zoom"], 8, 1.6, 12, 3.2, 16, 6],
      "circle-opacity": 0.75,
      "circle-stroke-color": "#ffffff",
      "circle-stroke-width": 0.4
    }
  });
  const popup = new maplibregl.Popup({closeButton: false, closeOnClick: false, offset: 8});
  m.on("mousemove", "places", e => {
    m.getCanvas().style.cursor = "pointer";
    const p = e.features[0].properties;
    popup.setLngLat(e.features[0].geometry.coordinates)
      .setHTML(`<strong>${p.name}</strong><br>${p.category}<br>Confidence ${(+p.confidence).toFixed(2)}`)
      .addTo(m);
  });
  m.on("mouseleave", "places", () => { m.getCanvas().style.cursor = ""; popup.remove(); });
  return m;
}
```

``` js
map.getSource("places").setData({
  type: "FeatureCollection",
  features: rows.map(d => ({
    type: "Feature",
    geometry: {type: "Point", coordinates: [d.lon, d.lat]},
    properties: {name: d.name, category: label(d.category), confidence: d.confidence, color: color(d.category)}
  }))
})
```

## By category

``` js
Plot.plot({
  width: 420,
  height: 440,
  marginLeft: 178,
  marginRight: 44,
  x: {label: null, grid: true, ticks: 4},
  y: {label: null},
  style: {backgroundColor: "transparent", fontSize: "11px"},
  marks: [
    Plot.barX(catRows, {x: d => d[1], y: d => label(d[0]), fill: d => color(d[0]), sort: {y: "-x"}, tip: true}),
    Plot.text(catRows, {x: d => d[1], y: d => label(d[0]), text: d => d[1].toLocaleString(), dx: 4, textAnchor: "start"}),
    Plot.ruleX([0])
  ]
})
```

## By city

``` js
Plot.plot({
  width: 420,
  height: 440,
  marginLeft: 110,
  marginRight: 44,
  x: {label: null, grid: true, ticks: 4},
  y: {label: null},
  style: {backgroundColor: "transparent", fontSize: "11px"},
  marks: [
    Plot.barX(knownCities.slice(0, 12), {x: d => d[1], y: d => d[0], fill: "#007EA7", sort: {y: "-x"}, tip: true}),
    Plot.text(knownCities.slice(0, 12), {x: d => d[1], y: d => d[0], text: d => d[1].toLocaleString(), dx: 4, textAnchor: "start"}),
    Plot.ruleX([0])
  ]
})
```

Expand ![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdib3g9IjAgMCAyNCAyNCIgc3R5bGU9ImhlaWdodDoxZW07d2lkdGg6MWVtOyIgYXJpYS1oaWRkZW49InRydWUiIHJvbGU9ImltZyI+PHBhdGggZD0iTTIwIDVDMjAgNC40IDE5LjYgNCAxOSA0SDEzQzEyLjQgNCAxMiAzLjYgMTIgM0MxMiAyLjQgMTIuNCAyIDEzIDJIMjFDMjEuNiAyIDIyIDIuNCAyMiAzVjExQzIyIDExLjYgMjEuNiAxMiAyMSAxMkMyMC40IDEyIDIwIDExLjYgMjAgMTFWNVpNNCAxOUM0IDE5LjYgNC40IDIwIDUgMjBIMTFDMTEuNiAyMCAxMiAyMC40IDEyIDIxQzEyIDIxLjYgMTEuNiAyMiAxMSAyMkgzQzIuNCAyMiAyIDIxLjYgMiAyMVYxM0MyIDEyLjQgMi40IDEyIDMgMTJDMy42IDEyIDQgMTIuNCA0IDEzVjE5WiIgLz48L3N2Zz4=)

![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdib3g9IjAgMCAxNiAxNiIgY2xhc3M9ImJpIGJpLWNoZXZyb24tbGVmdCBjb2xsYXBzZS1pY29uIiBzdHlsZT0iZmlsbDpjdXJyZW50Q29sb3I7IiBhcmlhLWhpZGRlbj0idHJ1ZSIgcm9sZT0iaW1nIj4KICAgICAgPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBkPSJNMTEuMzU0IDEuNjQ2YS41LjUgMCAwIDEgMCAuNzA4TDUuNzA3IDhsNS42NDcgNS42NDZhLjUuNSAwIDAgMS0uNzA4LjcwOGwtNi02YS41LjUgMCAwIDEgMC0uNzA4bDYtNmEuNS41IDAgMCAxIC43MDggMHoiIC8+CiAgICA8L3N2Zz4=)
