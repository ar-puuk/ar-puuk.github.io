Want a quick way to preview what is inside your Parquet file? Parquet Explorer is a browser-based, zero-backend viewer for Parquet and GeoParquet, built on DuckDB-WASM. Nothing is uploaded; everything runs locally in your tab.

Parquet and GeoParquet are compact, columnar binary formats, which is great for storage and analysis and less great when you just want to know what is in a file: you can’t double-click it and read it. Checking one usually means starting Python or R to print the schema and the first few rows, and plotting the geometry is a few more lines on top. I wanted to drop the file on a page and see its schema, its rows and, if it has geometry, a map. This post covers what the viewer does and the problems I ran into getting there, most of which were about geometry.

> **NOTE:**
>
> Since the first version it has gained support for Esri JSON geometries (rings, paths and x/y columns), clearer error messages for common failures like CORS, 403/404 and unsupported ZSTD compression (re-save with Snappy or Gzip), and a refreshed theme.

> **TIP:**
>
> The viewer cannot read ZSTD-compressed files. Re-save the file with Snappy or Gzip compression and open it again.

The live app is embedded below.

Parquet File Viewer

Fullscreen

[ Open app](https://ar-puuk.github.io/parquet-viewer/) [ GitHub](https://github.com/ar-puuk/parquet-viewer)

## 1 A quick tour

- **Open it three ways**: drop in a local file, paste an HTTP(S) URL, or paste an `s3://` URL for a public bucket. DuckDB fetches only the row groups it needs via range requests, so a large remote file doesn’t have to be downloaded in full.
- **See the schema first**: column names, types and nullability, plus row count, file size, row groups and (for spatial files) the geometry column, CRS and bounding box, all before any row data loads. Click a column for its min, max, null count and distinct count, sampled from up to 10,000 rows.
- **Query it**: a CodeMirror SQL editor with column autocomplete and a short query history, or a point-and-click query builder for select, filter, sort, limit and group-by aggregates, whose generated SQL stays visible and editable. The table of results is virtualized and sortable.
- **Map it**: GeoParquet and spatial files appear on a MapLibre map, synced with the table in both directions. Hover or click a row and the feature lights up on the map; click a feature and its row is selected and scrolled into view.

When a file opens, the viewer runs a default query, `SELECT * EXCLUDE (blob_cols) FROM data LIMIT 1000`, so there is something to look at right away. The `LIMIT` in your own SQL decides how many rows are loaded.

## 2 How it works

The app is React, TypeScript and Vite, deployed to GitHub Pages. [DuckDB-WASM](https://duckdb.org/docs/api/wasm/overview) does the heavy lifting: the file is registered with DuckDB’s virtual file system, a view called `data` points at it, and everything you see comes from SQL against that view. Schema, row count and file details come from `DESCRIBE`, `COUNT(*)` and DuckDB’s Parquet metadata functions, which only need the file’s footer, so they appear before any rows do. The map is [MapLibre GL](https://maplibre.org/) with an OpenFreeMap basemap, the table uses TanStack Virtual, and app state lives in a small Zustand store.

### Query first

The first design was a classic data viewer: a table that paged through the whole file on its own, with the map loading geometry in its own batches. It didn’t hold up. Accumulating rows into one growing array hung the browser on big files, and fetching the geometry column with every page of table rows meant tens of megabytes per request for complex polygons.

I rewrote it so the SQL panel drives everything. One query runs, its result goes into the store, and both the table and the map read from that same result. The query runner wraps your SQL to add a zero-based `__row_id`, and the map’s features carry the same id, which is what makes the table-to-map sync a simple lookup rather than a join. Binary columns (WKB geometry and other blobs) are excluded from the table query and shown as `[geometry]` or `[blob]`.

### Finding the geometry

Spatial detection has two tiers. A proper GeoParquet file has a `geo` entry in its key-value metadata, which names the geometry column, its encoding, its CRS and its bounding box; the map can zoom to that box before a single row is read. Plenty of spatial Parquet files don’t have that metadata, so the fallback looks for columns with the usual names (`geometry`, `geom`, `wkb_geometry`, `wkt`, `shape`) and works out the encoding from the type: binary is WKB, text is WKT. DuckDB’s spatial extension is loaded only when a spatial file is detected, so plain tables don’t pay for it.

## 3 The interesting problems

### Geometry comes in more shapes than I expected

WKB and WKT were straightforward: DuckDB’s `ST_GeomFromWKB` or `ST_GeomFromText`, then `ST_AsGeoJSON`, then onto the map. Two other encodings were not.

**GeoArrow structs.** Some files store geometry as native coordinate structs (DuckDB types like `POINT_2D` and `POLYGON_2D`) rather than as WKB. DuckDB-WASM’s spatial extension had no cast from those types to `GEOMETRY`, so the usual functions didn’t apply. One attempt built WKT strings out of the coordinate lists with plain SQL list and string functions, choosing `POINT`, `LINESTRING`, `POLYGON` or `MULTIPOLYGON` from the nesting depth in the column’s type name. Another converted features through `to_json()`, which turned out to return null for these types and silently drop every feature. The latest approach selects the raw column and converts the nested `{x, y}` objects to GeoJSON in JavaScript. The README still lists this encoding as a known limitation: such files are detected, but their features may not render.

**Esri JSON.** Files exported from ArcGIS tools often store the shape column as Esri JSON (`{"rings": [...], "spatialReference": {"wkid": 26912}}`). Since that is a text column, the viewer took it for WKT and DuckDB rejected it with “Expected geometry type near ‘{’”. The viewer now samples a value to tell Esri JSON from WKT, converts rings, paths, points and x/y pairs to GeoJSON itself, and reads the CRS straight from `spatialReference.wkid`. One more wrinkle followed a few days later: some tools write these as a Python dictionary’s string form, with single quotes, which `JSON.parse` refuses. Detection now looks for the keys as text, and parsing normalizes the quotes first.

### Projected coordinates

MapLibre wants longitude and latitude. A lot of planning data is in a projected system, such as UTM, and without GeoParquet metadata the file may not say which. The viewer samples a few coordinates, and if any have an absolute x over 180 or y over 90 it knows they can’t be degrees. A CRS panel then opens above the map: you can type an EPSG code, or click your study area on a small map to get a list of projections suggested for that location.

The obvious way to reproject, DuckDB’s `ST_Transform`, was unreliable in the browser build, so reprojection happens in JavaScript with [proj4js](https://github.com/proj4js/proj4js) after DuckDB returns GeoJSON. Until a CRS is set, the viewer deliberately pushes nothing to the map: feeding raw UTM eastings and northings to MapLibre could corrupt the map source so that later, correct data didn’t render either. Getting reprojected features to show up reliably also took fixing two race conditions in the map component, one where a “style loaded” event was awaited after it had already fired, and one where switching between light and dark styles wiped the layers and never refilled them.

### Stale bytes from the previous file

One bug looked like a compression problem and wasn’t. After opening one file and then another, the second sometimes failed with a ZSTD error even though it wasn’t ZSTD-compressed. DuckDB-WASM caches data keyed by file name, and every file was being registered as `data.parquet`, so reads of the new file could be served pages from the old one. Dropping the old file first helped; the complete fix gives each load a unique name (`data_1.parquet`, `data_2.parquet` and so on) while the `data` view always points at the current one.

### Column names that DuckDB doesn’t accept

The query builder at first generated explicit column lists from `DESCRIBE`, which reports names from the Parquet metadata. When a file has duplicate column names, DuckDB renames them (`_1`, `_2`) in queries but not in `DESCRIBE`, so the builder produced “column not found” errors. The schema now takes names from an empty `SELECT * ... LIMIT 0`, which returns exactly what DuckDB accepts, and the builder’s column picker hides columns in the table instead of rewriting the SQL.

### Explaining failures

Many failures come from outside the app: a server that doesn’t allow cross-origin requests, a private file, a wrong URL, or a ZSTD-compressed file that the WebAssembly build can’t decompress. The raw DuckDB messages for these aren’t helpful, so one function classifies errors and explains them in plain words, including the commands to re-save a file with Snappy compression. It is applied both when loading a file and when running a query, because a ZSTD file can pass the schema step (the footer isn’t compressed) and fail only on the first `SELECT`.

## 4 Limits and what’s next

The viewer reads public files only: no credentials, no private buckets. ZSTD-compressed files need to be re-saved with Snappy or Gzip, and GeoArrow struct geometry is the main encoding still listed as not rendering on the map. Those are the obvious places to improve.

The app was built in phases with Claude, which shows in the commit history: each phase and fix has a commit message explaining the cause. If you work with data and want a quick way to preview the contents of a `.parquet` file, give it a try. The code is on [GitHub](https://github.com/ar-puuk/parquet-viewer), and issues and PRs are welcome.

## Citation

BibTeX citation:

``` quarto-appendix-bibtex
@online{bhandari2026,
  author = {Bhandari, Pukar},
  title = {Building a {Client-Side} {Geo/Parquet} {File} {Viewer}},
  date = {2026-04-12},
  url = {https://ar-puuk.github.io/posts/parquet-explorer/},
  langid = {en-US}
}
```

For attribution, please cite this work as:

Bhandari, Pukar. 2026. “Building a Client-Side Geo/Parquet File Viewer.” April 12. <https://ar-puuk.github.io/posts/parquet-explorer/>.
