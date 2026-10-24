The National Center for Education Statistics publishes a remarkable amount of open data on schools and colleges, but spread across separate surveys with different file layouts, identifiers and release schedules. Looking up “what has happened to enrollment near this school?” means stitching several of them together.

Education Explorer does that stitching ahead of time and puts the result on a map. It is a sibling of my [freight explorer](../../posts/freight-explorer/index.llms.md): same idea (a static site, a local data pipeline, DuckDB in the browser), different data.

## 1 Try it

Education Explorer

Fullscreen

[ Open app](https://ar-puuk.github.io/education-explorer/) [ GitHub](https://github.com/ar-puuk/education-explorer)

## 2 What is in it

| Layer | Source | Years |
|----|----|----|
| Public schools and districts | NCES Common Core of Data (CCD) + EDGE locations | 1997-98 onward |
| Private schools | NCES Private School Universe Survey (PSS) | every survey, 1989-90 to 2023-24 |
| Colleges | NCES IPEDS | 1980 onward in the tables; map layer from 2000 |
| School district boundaries | Census TIGER/Line | 2010-11 onward |

Each layer has its own shape *and* color, so the map stays readable with all three on. Beyond the map you get:

- A **year slider** with play, and markers for the biennial private-school survey years.
- **Detail panels** with enrollment trends by race/ethnicity, sex and grade, free and reduced-price lunch, staff, finance, graduates, and IPEDS enrollment, awards and admissions.
- **Compare mode**, a table view with CSV export, and shareable URLs that carry the year, selection, filters, basemap and theme.
- Light, dark and system themes, and five OpenFreeMap basemaps.

> **NOTE:**
>
> It shows data and caveats only. It does not rank schools, compute quality scores or recommend anything, and a [Data and methods](https://ar-puuk.github.io/education-explorer/methodology.html) page documents every source and release.

## 3 How it works

``` mermaid
flowchart LR
  A["NCES / Census files"] --> B["Local pipeline<br>Python + DuckDB"]
  B --> C["Parquet in docs/data/"]
  C --> D["GitHub Pages"]
  D --> E["Browser: DuckDB-WASM<br>reads byte ranges"]
```

The first paint comes from small JSON “points” files; DuckDB-WASM loads afterwards and reads only the Parquet byte ranges a query needs. There is no backend, no GitHub Actions and no key-gated service, so the site costs nothing to run.

Updating after NCES publishes a new release is two commands:

``` bash
cd pipeline
uv run python -m nces_pipeline fetch --check-only # <1>
uv run python -m nces_pipeline update # <2>
```

1.  List what is new without downloading anything.
2.  Fetch, build, geocode, build boundaries and the dictionary, then validate. It prints a changelog of row-count changes.

NCES changes file layouts often, so the build includes a **schema-drift guard**. When a release adds, drops or renames a column, the build stops and names the nearest known column (`+ NEWCOL not in the map (nearest known: OLDCOL)`). Validation also rejects row counts that fall more than 20% from the committed baseline and coordinates that land outside the state’s bounding box.

Nothing in the code is specific to a state; the state shown is set by one config file. The code is on [GitHub](https://github.com/ar-puuk/education-explorer).

## Citation

BibTeX citation:

``` quarto-appendix-bibtex
@online{bhandari2026,
  author = {Bhandari, Pukar},
  title = {An {Education} {Explorer} for {Public} {NCES} {Data}},
  date = {2026-10-19},
  url = {https://ar-puuk.github.io/posts/education-explorer/},
  langid = {en}
}
```

For attribution, please cite this work as:

Bhandari, Pukar. 2026. “An Education Explorer for Public NCES Data.” October 19. <https://ar-puuk.github.io/posts/education-explorer/>.
