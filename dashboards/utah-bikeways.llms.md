``` js
data = FileAttachment("../posts/utah-bikeways/_output/miles_by_city.csv").csv({typed: true})
types = ["Paved Path", "Protected Bike Lane", "Bike Lane", "Marked Route", "Unmarked Route"]
```

Municipalities

``` js
rows.length
```

Selected bikeway miles

``` js
html`${totalBike.toLocaleString(undefined, {maximumFractionDigits: 0})}`
```

Statewide bikeway share of roads

``` js
html`${(totalBike / totalRoad * 100).toFixed(1)}%`
```

Highest share (over 100 road miles)

``` js
html`${top.Name} ${top.ratio.toFixed(1)}%`
```

Bikeway miles against road miles

``` js
Plot.plot({
  width: 720,
  height: 440,
  marginBottom: 44,
  grid: true,
  x: {label: "Total road miles (log) →", type: "log", domain: [10, 5000]},
  y: {label: "Selected bikeway miles (log) →", type: "log", domain: [0.1, 500]},
  color: {domain: ["Above average", "Below average"], range: ["#007EA7", "#D96E34"], legend: true},
  style: {backgroundColor: "transparent", fontSize: "12px"},
  marks: [
    Plot.line(d3.range(10, 5000, 100), {x: d => d, y: d => d * avgRatio / 100, stroke: "#888", strokeDasharray: "4,4"}),
    Plot.dot(rowsTagged.filter(d => d.bike > 0), {x: "All Roads", y: "bike", stroke: "group", fill: "group", fillOpacity: 0.3, r: 4, tip: true,
      title: d => `${d.Name}
Bikeway: ${d.bike.toFixed(1)} mi
Roads: ${d["All Roads"]} mi
Share: ${d.ratio.toFixed(1)}%`}),
    Plot.dot(highlighted, {x: "All Roads", y: "bike", stroke: "currentColor", strokeWidth: 2, r: 8}),
    Plot.text(highlighted, {x: "All Roads", y: "bike", text: "Name", dy: -16, fontWeight: "bold", stroke: "white", strokeWidth: 4, paintOrder: "stroke", fill: "#333"})
  ]
})
```

Expand ![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdib3g9IjAgMCAyNCAyNCIgc3R5bGU9ImhlaWdodDoxZW07d2lkdGg6MWVtOyIgYXJpYS1oaWRkZW49InRydWUiIHJvbGU9ImltZyI+PHBhdGggZD0iTTIwIDVDMjAgNC40IDE5LjYgNCAxOSA0SDEzQzEyLjQgNCAxMiAzLjYgMTIgM0MxMiAyLjQgMTIuNCAyIDEzIDJIMjFDMjEuNiAyIDIyIDIuNCAyMiAzVjExQzIyIDExLjYgMjEuNiAxMiAyMSAxMkMyMC40IDEyIDIwIDExLjYgMjAgMTFWNVpNNCAxOUM0IDE5LjYgNC40IDIwIDUgMjBIMTFDMTEuNiAyMCAxMiAyMC40IDEyIDIxQzEyIDIxLjYgMTEuNiAyMiAxMSAyMkgzQzIuNCAyMiAyIDIxLjYgMiAyMVYxM0MyIDEyLjQgMi40IDEyIDMgMTJDMy42IDEyIDQgMTIuNCA0IDEzVjE5WiIgLz48L3N2Zz4=)

Top 12 by bikeway miles

``` js
Plot.plot({
  width: 460,
  height: 440,
  marginLeft: 110,
  marginRight: 70,
  x: {label: null, grid: true, ticks: 4},
  y: {label: null},
  color: {domain: ["Above average", "Below average"], range: ["#007EA7", "#D96E34"]},
  style: {backgroundColor: "transparent", fontSize: "12px"},
  marks: [
    Plot.barX(d3.sort(rowsTagged, d => -d.bike).slice(0, 12), {x: "bike", y: "Name", fill: "group", sort: {y: "-x"}, tip: true,
      title: d => `${d.Name}
Bikeway: ${d.bike.toFixed(1)} mi
Share: ${d.ratio.toFixed(1)}%`}),
    Plot.text(d3.sort(rowsTagged, d => -d.bike).slice(0, 12), {x: "bike", y: "Name", text: d => `${d.bike.toFixed(1)} mi · ${d.ratio.toFixed(0)}%`, dx: 4, textAnchor: "start", fontSize: 10}),
    Plot.ruleX([0])
  ]
})
```

Expand ![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdib3g9IjAgMCAyNCAyNCIgc3R5bGU9ImhlaWdodDoxZW07d2lkdGg6MWVtOyIgYXJpYS1oaWRkZW49InRydWUiIHJvbGU9ImltZyI+PHBhdGggZD0iTTIwIDVDMjAgNC40IDE5LjYgNCAxOSA0SDEzQzEyLjQgNCAxMiAzLjYgMTIgM0MxMiAyLjQgMTIuNCAyIDEzIDJIMjFDMjEuNiAyIDIyIDIuNCAyMiAzVjExQzIyIDExLjYgMjEuNiAxMiAyMSAxMkMyMC40IDEyIDIwIDExLjYgMjAgMTFWNVpNNCAxOUM0IDE5LjYgNC40IDIwIDUgMjBIMTFDMTEuNiAyMCAxMiAyMC40IDEyIDIxQzEyIDIxLjYgMTEuNiAyMiAxMSAyMkgzQzIuNCAyMiAyIDIxLjYgMiAyMVYxM0MyIDEyLjQgMi40IDEyIDMgMTJDMy42IDEyIDQgMTIuNCA0IDEzVjE5WiIgLz48L3N2Zz4=)

![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdib3g9IjAgMCAxNiAxNiIgY2xhc3M9ImJpIGJpLWNoZXZyb24tbGVmdCBjb2xsYXBzZS1pY29uIiBzdHlsZT0iZmlsbDpjdXJyZW50Q29sb3I7IiBhcmlhLWhpZGRlbj0idHJ1ZSIgcm9sZT0iaW1nIj4KICAgICAgPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBkPSJNMTEuMzU0IDEuNjQ2YS41LjUgMCAwIDEgMCAuNzA4TDUuNzA3IDhsNS42NDcgNS42NDZhLjUuNSAwIDAgMS0uNzA4LjcwOGwtNi02YS41LjUgMCAwIDEgMC0uNzA4bDYtNmEuNS41IDAgMCAxIC43MDggMHoiIC8+CiAgICA8L3N2Zz4=)
