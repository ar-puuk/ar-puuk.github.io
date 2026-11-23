I used to keep my reusable R functions in a separate repository and copy whatever I needed from it into each new project. `pukRhelpers` is where those small functions ended up. In February 2025 I moved them into a proper R package, so there is one copy, with documentation, that any project can install instead of a pasted file that drifts out of date.

It is a personal toolbox, not a polished library. Most of the functions exist because a project needed them, and I only update the package when my own work needs something. This post is a short tour of what is in it, the one function that turned into a bug report upstream, and a live demo you can run in your browser.

[ Docs](https://ar-puuk.github.io/pukRhelpers/) [ GitHub](https://github.com/ar-puuk/pukRhelpers)

## 1 Install

``` r
pak::pak("ar-puuk/pukRhelpers") # <1>
install.packages("pukRhelpers", repos = "https://ar-puuk.r-universe.dev") # <2>
```

1.  Straight from GitHub. `remotes::install_github()` and `devtools::install_github()` work too.
2.  Or from my personal R-universe.

## 2 What is in it

Most of my work is transportation and GIS data in Utah, so the package leans on two sources: ArcGIS REST services, where a lot of public agency data lives, and Utah’s State Geographic Information Database (SGID), maintained by the Utah Geospatial Resource Center (UGRC). The rest is spatial plumbing that kept coming up.

| Function | What it does |
|----|----|
| `load_esri()` | Load and query an ESRI Feature Service layer |
| `arc_read_encode()` | `arcgislayers::arc_read()` with coded-value encoding built in, so no stray helper objects are left in the environment |
| `load_ugrc_data()`, `load_ugrc_vars()` | Load a dataset, or list the datasets, from Utah’s SGID |
| `load_kml_sf()` | Convert KML to an `sf` object with attributes preserved |
| `st_aggregate()` | Aggregate `sf` objects |
| `geo_split_lines()`, `st_split_lines()` | Split lines by a maximum length |
| `convert_fgb_to_gdb()` | Convert FlatGeobuf files to geodatabase layers |
| `convert_xml_html()`, `extract_html_table()` | XML to HTML via XSLT, and pull a table out of an HTML page by its anchor |
| `load_packages()` | Load, installing first if needed |

Several of these build on other people’s gists and are credited to them in the function documentation and the [README](https://github.com/ar-puuk/pukRhelpers).

## 3 A quick tour

### Getting data out of ArcGIS and the SGID

`load_esri()` is a thin layer over [arcgislayers](https://github.com/R-ArcGIS/arcgislayers). Give it the URL of a Feature Service and a layer id and it returns an `sf` object. Any other arguments go straight to `arcgislayers::arc_select()`, so you can filter on the server. If you leave the id out, it prints the service’s layers with their ids and asks which one you want, which is handy when exploring a service for the first time.

``` r
library(pukRhelpers)

# List the layers, then pick one at the prompt
layer <- load_esri("https://.../FeatureServer")

# Or ask for a layer directly and filter on the server
layer <- load_esri("https://.../FeatureServer", id = 0, where = "...")
```

`load_ugrc_vars()` and `load_ugrc_data()` do the same for the SGID. UGRC runs a public, read-only PostgreSQL copy of it called Open SGID, so instead of downloading a shapefile, these functions connect to that database, list its tables, or read one table as an `sf` object:

``` r
tables <- load_ugrc_vars()   # schema and table names
uta_stops <- load_ugrc_data("transportation.uta_stops_and_ridership")
```

### File format chores

`load_kml_sf()` deals with KML files that keep their attributes as one block of text in the `Description` field, with lines like `Owner: City` separated by `<br>`. It reads the KML with `sf`, splits that field into `label: value` pairs, and turns each label into its own column. It builds on [a gist by Michael Sumner](https://gist.github.com/mdsumner/1469b4ab53058e33bafc4fd9cda454eb).

`convert_fgb_to_gdb()` takes a folder of FlatGeobuf files and writes each one as a layer in a file geodatabase through GDAL’s OpenFileGDB driver, which is handy when the next person in the chain works in ArcGIS Pro. It skips layers that are already in the geodatabase unless you ask it to overwrite, and it replaces dots in column names with underscores on the way. `convert_xml_html()` and `extract_html_table()` handle the occasional XML metadata file and HTML report.

### Two ways to split a line

Both line splitters come from [a gist by David Blodgett](https://gist.github.com/dblodgett-usgs/cf87392c02d73f1b7d16153d2b66a8f3) and do the same job: break every line longer than `max_length` into equal-length pieces that are all under it. They differ in how they cut.

- `st_split_lines()` works from the line’s own vertices. It measures the distance along the line at each vertex and cuts at the vertex closest to each ideal break point, so the pieces use only points that were already there.
- `geo_split_lines()` uses `lwgeom::st_linesubstring()` to cut at exact fractions of the length, so the pieces really are equal, with new vertices at the cuts. It also warns you when `max_length` is under 50, since that usually means the units are not what you think.

## 4 The function that went upstream

The newest function, `arc_read_encode()`, has a small story behind it. A lot of ArcGIS data stores categories as coded values. UGRC’s statewide roads layer, for example, has a cartographic code field (`CARTOCODE`) whose values are codes, with the meaning of each code kept in the layer’s domain. `arcgislayers` can translate those with `encode_field_values()`, but that needs the layer object as well as the data, so every read became several steps and left extra objects in my environment.

In February 2025 I [asked on the arcgislayers discussion board](https://github.com/R-ArcGIS/arcgislayers/discussions/234) how best to work with coded values, and while trying the answers I found that `encode_field_values()` failed with its default `field = NULL` on that same roads layer. That became [issue \#237](https://github.com/R-ArcGIS/arcgislayers/issues/237). Meanwhile I wrote `arc_read_encode()`: a copy of `arc_read()` with two extra arguments, `encode_field_values` (`TRUE` for every field, or a vector of field names) and `codes` (replace the codes with their labels, or keep them and attach the labels). It opens the layer, selects the data and encodes it in one call:

``` r
roads <- arc_read_encode(
  "https://services1.arcgis.com/99lidPhWCzftIe9K/ArcGIS/rest/services/UtahRoads/FeatureServer/0",
  n_max = 100,
  encode_field_values = "CARTOCODE"
)
```

Like `arc_read()`, it also accepts tables and ImageServer URLs (an ImageServer returns a raster), and anything else gets a clear error.

Adding it in May 2025 is also when I set the package up properly: GitHub Actions now run `R CMD check`, rebuild the [pkgdown site](https://ar-puuk.github.io/pukRhelpers/) and report test coverage to Codecov.

## 5 Try one in your browser

The package itself cannot run inside a web page: it talks to ArcGIS services and databases, and it needs system libraries that browsers do not have. `st_aggregate()` is different, because it is plain `sf` and base R. The code below is copied from the package and run on the North Carolina counties that ship with `sf`.

Edit anything and press **Run code**: the cells run in your browser.

`st_aggregate()` comes from [a gist by rCarto](https://gist.github.com/rCarto/bb47aff0a02e808d2bf64f2d8c5db7d8), and the package credits it the same way.

First, load the counties and sort them into three zones:

Then define the function. It joins the geometries of each zone with `st_union()` and summarises the attributes you ask for:

Now aggregate: the mean and median births per zone, with the counties merged into three shapes. Try changing `"BIR74"` to `"SID74"`, or `"mean"` to `"max"`:

## 6 What it doesn’t do

Because it grew out of my own scripts, the package has rough edges I have not needed to fix yet. `load_esri()` prompts for input when you leave out the layer id, so in a script or a Quarto document you should always pass one. The Open SGID functions need the database to be reachable on its PostgreSQL port, which some networks block. And the test suite is still a placeholder: CI checks that the package builds, installs and documents cleanly, not that each function gives the right answer.

When I catch myself copying a new function between projects, it will end up here. If one of them is useful to you, take it. The code is on [GitHub](https://github.com/ar-puuk/pukRhelpers) under GPL-3, and the functions that came from other people’s gists say so in their documentation.

## Citation

BibTeX citation:

``` quarto-appendix-bibtex
@online{bhandari2025,
  author = {Bhandari, Pukar},
  title = {pukRhelpers: {A} {Personal} {Toolbox} of {R} {Helpers}},
  date = {2025-05-23},
  url = {https://ar-puuk.github.io/posts/pukrhelpers/},
  langid = {en-US}
}
```

For attribution, please cite this work as:

Bhandari, Pukar. 2025. “pukRhelpers: A Personal Toolbox of R Helpers.” May 23. <https://ar-puuk.github.io/posts/pukrhelpers/>.
