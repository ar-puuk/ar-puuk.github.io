``` js
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
categoryCounts = d3.rollups(places, v => v.length, d => d.category).sort((a, b) => b[1] - a[1])
topCategories = categoryCounts.slice(0, 40).map(d => d[0])
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
cityCounts.filter(d => d[0] !== "Unknown").length
```

Busiest city

``` js
html`${cityCounts.length ? cityCounts[0][0] + " " + cityCounts[0][1].toLocaleString() : "none"}`
```

Where the selected places are

``` js
Plot.plot({
  width: 640,
  height: 440,
  aspectRatio: 1 / Math.cos(40.7 * Math.PI / 180),
  x: {label: "Longitude", ticks: 5},
  y: {label: "Latitude", ticks: 5},
  color: {legend: true},
  style: {backgroundColor: "transparent"},
  marks: [
    Plot.dot(rows, {x: "lon", y: "lat", fill: d => d.category.replaceAll('_', ' '), r: 1.6, fillOpacity: 0.55, tip: true,
      title: d => `${d.name}\n${d.category}\nConfidence ${d.confidence.toFixed(2)}`})
  ]
})
```

Expand ![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdib3g9IjAgMCAyNCAyNCIgc3R5bGU9ImhlaWdodDoxZW07d2lkdGg6MWVtOyIgYXJpYS1oaWRkZW49InRydWUiIHJvbGU9ImltZyI+PHBhdGggZD0iTTIwIDVDMjAgNC40IDE5LjYgNCAxOSA0SDEzQzEyLjQgNCAxMiAzLjYgMTIgM0MxMiAyLjQgMTIuNCAyIDEzIDJIMjFDMjEuNiAyIDIyIDIuNCAyMiAzVjExQzIyIDExLjYgMjEuNiAxMiAyMSAxMkMyMC40IDEyIDIwIDExLjYgMjAgMTFWNVpNNCAxOUM0IDE5LjYgNC40IDIwIDUgMjBIMTFDMTEuNiAyMCAxMiAyMC40IDEyIDIxQzEyIDIxLjYgMTEuNiAyMiAxMSAyMkgzQzIuNCAyMiAyIDIxLjYgMiAyMVYxM0MyIDEyLjQgMi40IDEyIDMgMTJDMy42IDEyIDQgMTIuNCA0IDEzVjE5WiIgLz48L3N2Zz4=)

Places by category

``` js
Plot.plot({
  width: 520,
  height: 440,
  marginLeft: 150,
  x: {label: "Places →", grid: true},
  y: {label: null},
  style: {backgroundColor: "transparent"},
  marks: [
    Plot.barX(catRows, {x: d => d[1], y: d => d[0].replaceAll('_', ' '), sort: {y: "-x"}, fill: "#007EA7", tip: true}),
    Plot.ruleX([0])
  ]
})
```

Expand ![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdib3g9IjAgMCAyNCAyNCIgc3R5bGU9ImhlaWdodDoxZW07d2lkdGg6MWVtOyIgYXJpYS1oaWRkZW49InRydWUiIHJvbGU9ImltZyI+PHBhdGggZD0iTTIwIDVDMjAgNC40IDE5LjYgNCAxOSA0SDEzQzEyLjQgNCAxMiAzLjYgMTIgM0MxMiAyLjQgMTIuNCAyIDEzIDJIMjFDMjEuNiAyIDIyIDIuNCAyMiAzVjExQzIyIDExLjYgMjEuNiAxMiAyMSAxMkMyMC40IDEyIDIwIDExLjYgMjAgMTFWNVpNNCAxOUM0IDE5LjYgNC40IDIwIDUgMjBIMTFDMTEuNiAyMCAxMiAyMC40IDEyIDIxQzEyIDIxLjYgMTEuNiAyMiAxMSAyMkgzQzIuNCAyMiAyIDIxLjYgMiAyMVYxM0MyIDEyLjQgMi40IDEyIDMgMTJDMy42IDEyIDQgMTIuNCA0IDEzVjE5WiIgLz48L3N2Zz4=)

![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdib3g9IjAgMCAxNiAxNiIgY2xhc3M9ImJpIGJpLWNoZXZyb24tbGVmdCBjb2xsYXBzZS1pY29uIiBzdHlsZT0iZmlsbDpjdXJyZW50Q29sb3I7IiBhcmlhLWhpZGRlbj0idHJ1ZSIgcm9sZT0iaW1nIj4KICAgICAgPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBkPSJNMTEuMzU0IDEuNjQ2YS41LjUgMCAwIDEgMCAuNzA4TDUuNzA3IDhsNS42NDcgNS42NDZhLjUuNSAwIDAgMS0uNzA4LjcwOGwtNi02YS41LjUgMCAwIDEgMC0uNzA4bDYtNmEuNS41IDAgMCAxIC43MDggMHoiIC8+CiAgICA8L3N2Zz4=)
