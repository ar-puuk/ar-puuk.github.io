Want a quick way to preview what is inside your parquet file? This is a browser-based, zero-backend viewer for Parquet and GeoParquet, built on DuckDB-WASM. Nothing is uploaded; everything runs locally in your tab.

- **Open it three ways**: drop in a local file, paste an HTTP(S) URL, or paste an `s3://` URL for a public bucket. DuckDB fetches only the row groups it needs via range requests.
- **See the schema first**: column names, types and nullability, plus row count, file size, row groups and (for spatial files) the geometry column, CRS and bounding box, all before any row data loads.
- **Query it**: a CodeMirror SQL editor with column autocomplete, or a point-and-click query builder whose generated SQL stays visible and editable.
- **Map it**: GeoParquet and spatial files appear on a MapLibre map, synced with the table in both directions.

> **TIP:**
>
> Since the first version it has gained support for Esri JSON geometries (rings, paths and x/y columns), clearer error messages for common failures like CORS, 403/404 and unsupported ZSTD compression (re-save with Snappy or Gzip), and a refreshed theme.

The live app is embedded below.

Parquet File Viewer

Fullscreen

[ Open app](https://ar-puuk.github.io/parquet-viewer/) [ GitHub](https://github.com/ar-puuk/parquet-viewer)

If you work with data and want a quick way to preview the contents of a `.parquet` file, give it a try. The code is on [GitHub](https://github.com/ar-puuk/parquet-viewer) — issues and PRs welcome.

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
