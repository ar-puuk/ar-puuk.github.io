`pukRhelpers` is where the small functions I kept copying between projects ended up. It is a personal toolbox, not a polished library, and I only update it when my own work needs something. The package has continuous checks and test coverage set up, and documentation at [ar-puuk.github.io/pukRhelpers](https://ar-puuk.github.io/pukRhelpers/).

[ Docs](https://ar-puuk.github.io/pukRhelpers/) [ GitHub](https://github.com/ar-puuk/pukRhelpers)

## 1 Install

``` r
pak::pak("ar-puuk/pukRhelpers") # <1>
install.packages("pukRhelpers", repos = "https://ar-puuk.r-universe.dev") # <2>
```

1.  Straight from GitHub. `remotes::install_github()` and `devtools::install_github()` work too.
2.  Or from my personal R-universe.

## 2 What is in it

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

The code is on [GitHub](https://github.com/ar-puuk/pukRhelpers) under GPL-3.

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
