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

Highest share (cities over 100 road miles)

``` js
html`${top.Name} ${top.ratio.toFixed(1)}%`
```

Bikeway miles against road miles

``` js
Plot.plot({
  width: 700,
  height: 440,
  grid: true,
  x: {label: "Total road miles (log) →", type: "log", domain: [10, 5000]},
  y: {label: "Selected bikeway miles (log) →", type: "log", domain: [0.1, 500]},
  color: {domain: ["Above average", "Below average"], range: ["#007EA7", "#D96E34"], legend: true},
  style: {backgroundColor: "transparent"},
  marks: [
    Plot.line(d3.range(10, 5000, 100), {x: d => d, y: d => d * avgRatio / 100, stroke: "#888", strokeDasharray: "4,4"}),
    Plot.dot(rowsTagged.filter(d => d.bike > 0), {x: "All Roads", y: "bike", stroke: "group", fill: "group", fillOpacity: 0.3, r: 4, tip: true,
      title: d => `${d.Name}\nBikeway: ${d.bike.toFixed(1)} mi\nRoads: ${d["All Roads"]} mi\nShare: ${d.ratio.toFixed(1)}%`}),
    Plot.dot(highlighted, {x: "All Roads", y: "bike", stroke: "currentColor", strokeWidth: 2, r: 8}),
    Plot.text(highlighted, {x: "All Roads", y: "bike", text: "Name", dy: -16, fontWeight: "bold", stroke: "white", strokeWidth: 4, paintOrder: "stroke", fill: "#333"})
  ]
})
```

Expand ![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdib3g9IjAgMCAyNCAyNCIgc3R5bGU9ImhlaWdodDoxZW07d2lkdGg6MWVtOyIgYXJpYS1oaWRkZW49InRydWUiIHJvbGU9ImltZyI+PHBhdGggZD0iTTIwIDVDMjAgNC40IDE5LjYgNCAxOSA0SDEzQzEyLjQgNCAxMiAzLjYgMTIgM0MxMiAyLjQgMTIuNCAyIDEzIDJIMjFDMjEuNiAyIDIyIDIuNCAyMiAzVjExQzIyIDExLjYgMjEuNiAxMiAyMSAxMkMyMC40IDEyIDIwIDExLjYgMjAgMTFWNVpNNCAxOUM0IDE5LjYgNC40IDIwIDUgMjBIMTFDMTEuNiAyMCAxMiAyMC40IDEyIDIxQzEyIDIxLjYgMTEuNiAyMiAxMSAyMkgzQzIuNCAyMiAyIDIxLjYgMiAyMVYxM0MyIDEyLjQgMi40IDEyIDMgMTJDMy42IDEyIDQgMTIuNCA0IDEzVjE5WiIgLz48L3N2Zz4=)

Top 15 by bikeway miles

``` js
Inputs.table(
  [...rows].sort((a, b) => b.bike - a.bike).slice(0, 15),
  {
    columns: ["Name", "bike", "All Roads", "ratio"],
    header: {Name: "City", bike: "Bike mi", "All Roads": "Road mi", ratio: "Share %"},
    format: {bike: x => x.toFixed(1), "All Roads": x => x.toFixed(0), ratio: x => x.toFixed(1)},
    rows: 15, maxHeight: 520
  }
)
```

Expand ![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdib3g9IjAgMCAyNCAyNCIgc3R5bGU9ImhlaWdodDoxZW07d2lkdGg6MWVtOyIgYXJpYS1oaWRkZW49InRydWUiIHJvbGU9ImltZyI+PHBhdGggZD0iTTIwIDVDMjAgNC40IDE5LjYgNCAxOSA0SDEzQzEyLjQgNCAxMiAzLjYgMTIgM0MxMiAyLjQgMTIuNCAyIDEzIDJIMjFDMjEuNiAyIDIyIDIuNCAyMiAzVjExQzIyIDExLjYgMjEuNiAxMiAyMSAxMkMyMC40IDEyIDIwIDExLjYgMjAgMTFWNVpNNCAxOUM0IDE5LjYgNC40IDIwIDUgMjBIMTFDMTEuNiAyMCAxMiAyMC40IDEyIDIxQzEyIDIxLjYgMTEuNiAyMiAxMSAyMkgzQzIuNCAyMiAyIDIxLjYgMiAyMVYxM0MyIDEyLjQgMi40IDEyIDMgMTJDMy42IDEyIDQgMTIuNCA0IDEzVjE5WiIgLz48L3N2Zz4=)

![](data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdib3g9IjAgMCAxNiAxNiIgY2xhc3M9ImJpIGJpLWNoZXZyb24tbGVmdCBjb2xsYXBzZS1pY29uIiBzdHlsZT0iZmlsbDpjdXJyZW50Q29sb3I7IiBhcmlhLWhpZGRlbj0idHJ1ZSIgcm9sZT0iaW1nIj4KICAgICAgPHBhdGggZmlsbC1ydWxlPSJldmVub2RkIiBkPSJNMTEuMzU0IDEuNjQ2YS41LjUgMCAwIDEgMCAuNzA4TDUuNzA3IDhsNS42NDcgNS42NDZhLjUuNSAwIDAgMS0uNzA4LjcwOGwtNi02YS41LjUgMCAwIDEgMC0uNzA4bDYtNmEuNS41IDAgMCAxIC43MDggMHoiIC8+CiAgICA8L3N2Zz4=)
