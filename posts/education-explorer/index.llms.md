The National Center for Education Statistics publishes a remarkable amount of open data on schools and colleges, but spread across separate surveys with different file layouts, identifiers and release schedules. Looking up “what has happened to enrollment near this school?” means stitching several of them together.

Education Explorer does that stitching ahead of time and puts the result on a map. It is a sibling of my [freight explorer](../../posts/freight-explorer/index.llms.md): same idea (a static site, a local data pipeline, DuckDB in the browser), different data. Education Explorer came first, and the freight project reused its conventions.

This post covers what the explorer shows, how it is built, and the parts of the pipeline that took the most work: finding the files, surviving forty years of changing layouts, and getting every school onto the map.

## 1 Try it

Education Explorer

Fullscreen

[ Open app](https://ar-puuk.github.io/education-explorer/) [ Data and methods](https://ar-puuk.github.io/education-explorer/methodology.html) [ GitHub](https://github.com/ar-puuk/education-explorer) [ DOI](https://doi.org/10.5281/zenodo.23789925)

## 2 Why NCES data is hard to use

There is no single “schools” dataset. NCES runs three separate collections, each with its own key:

- the **Common Core of Data (CCD)** for public schools and districts, keyed on `NCESSCH` and `LEAID`;
- the **Private School Universe Survey (PSS)**, keyed on `PPIN`, collected every two years;
- **IPEDS** for colleges and universities, keyed on `UNITID`.

Each one is distributed differently. The CCD file page is rendered by JavaScript from a JSON API, and the file names carry release dates and version codes, so the URLs cannot be guessed. The IPEDS file catalogue sits behind an ASP.NET postback form. Older CCD years exist only as SAS files (and the very oldest only as fixed-width text). The modern CCD membership file is a 2.3 GB national CSV, of which Utah is a small slice. And the CCD school directory, the obvious place to look for coordinates, has no latitude or longitude at all; those live in a separate NCES product (EDGE).

None of this is hidden. It is just a lot of plumbing between a question and an answer, and the plumbing changes every year.

## 3 A quick tour

| Layer | Source | Years |
|----|----|----|
| Public schools and districts | NCES Common Core of Data (CCD) + EDGE locations | 1997-98 onward |
| Private schools | NCES Private School Universe Survey (PSS) | every survey, 1989-90 to 2023-24 |
| Colleges | NCES IPEDS | 1980 onward in the tables; map layer from 2000 |
| School district boundaries | Census TIGER/Line | 2010-11 onward |

Each layer has its own shape *and* color, so the map stays readable with all three on. Beyond the map you get:

- A **year slider** with play, a histogram of places per year, and markers for the biennial private-school survey years.
- **Detail panels** with enrollment trends by race/ethnicity, sex and grade, free and reduced-price lunch, staff, finance, graduates, and IPEDS enrollment, awards and admissions. Colleges also get online course load, retention and graduation, tuition and net price, and revenue and spending.
- A **table explorer** for every IPEDS and PSS table, with dictionary labels and CSV export.
- **Compare mode** (up to four places), a table view with CSV export, and shareable URLs that carry the year, selection, filters, basemap and theme.
- Optional marker coloring by school level, charter status or locale (the shape never changes, so color is never the only cue).
- Light, dark and system themes, and five OpenFreeMap basemaps.

> **NOTE:**
>
> It shows data and caveats only. It does not rank schools, compute quality scores or recommend anything, and a [Data and methods](https://ar-puuk.github.io/education-explorer/methodology.html) page documents every source and release.

That rule shaped several small decisions. The admissions chart shows counts of applicants, admits and enrollees rather than a selectivity score. Where a school’s figures are shown against the state, the reference is the median and middle half of operating public schools, never a rank or percentile. Charts that could be read as quality (ratios, spending, graduation) carry a descriptive-only note.

## 4 How it works

``` mermaid
flowchart LR
  A["NCES / Census files"] --> B["Local pipeline<br>Python + DuckDB"]
  B --> C["Parquet in docs/data/"]
  C --> D["GitHub Pages"]
  D --> E["Browser: DuckDB-WASM<br>reads byte ranges"]
```

The first paint comes from small JSON “points” files; DuckDB-WASM loads afterwards and reads only the Parquet byte ranges a query needs. There is no backend, no GitHub Actions and no key-gated service, so the site costs nothing to run. Before writing any app code I checked that GitHub Pages answers range requests for Parquet (it returns `206 Partial Content` with CORS headers), because the whole design depended on it.

Two details of shipping DuckDB to a static host:

- GitHub Pages does not compress `.wasm` files, and the DuckDB engine is 36 MB raw. The site ships it gzipped (about 8 MB) and inflates it in the browser.
- DuckDB-WASM normally downloads its Parquet extension from `extensions.duckdb.org` at runtime. The site hosts that extension itself, so the browser talks only to the site and to the OpenFreeMap tile server, and a smoke test asserts exactly that.

The front end is Vite, Svelte 5 and TypeScript, with MapLibre for the map and Observable Plot for the charts. The pipeline is Python run with [uv](https://docs.astral.sh/uv/), doing almost all of its work in DuckDB SQL.

Updating after NCES publishes a new release is two commands:

``` bash
cd pipeline
uv run python -m nces_pipeline fetch --check-only # <1>
uv run python -m nces_pipeline update # <2>
```

1.  List what is new without downloading anything.
2.  Fetch, build, geocode, build boundaries and the dictionary, then validate. It prints a changelog of row-count changes.

## 5 The hard parts

### Finding the files

Because none of the three sources has a stable, guessable file list, each one needed its own discovery step. CCD files come from the NCES datatables JSON API, queried one school year at a time (asking for all years at once returns a server error). The IPEDS catalogue is scraped from its ASP.NET form, one postback per survey year, and the files come from the complete-data-files directory. Raw downloads stay on my machine; only a manifest with each file’s URL and SHA-256 hash is committed.

The API is not complete either. The district finance files (F-33) are missing from the CCD listing, so the pipeline reads a short list of extra files from `config/ccd_extra_files.yml` for exactly that case.

### Forty years of changing layouts

NCES changes file layouts often: columns are added, dropped and renamed, and the older files use survey-year suffixes on column names. Every source therefore has a YAML column map. CCD has one map per topic and year; IPEDS and PSS have one map per table, with a year range on each column, which avoids writing roughly 850 near-identical files for IPEDS alone.

The build includes a **schema-drift guard**. When a release adds, drops or renames a column, the build stops and names the nearest known column:

``` text
+ NEWCOL not in the map (nearest known: OLDCOL)
```

The guard also checks types, and that is where the most instructive bug came from. Column types were first sniffed from Utah’s own rows. A smoke run for Colorado then failed: an IPEDS column that held only numbers in Utah held text codes in Colorado. Types are now sniffed from the national files, never the state subset, and any non-empty value that will not cast to its mapped type fails the build. (Integers are detected with a regular expression, because DuckDB’s `TRY_CAST('40.76' AS BIGINT)` quietly rounds instead of failing.) The same Colorado run showed that IPEDS uniqueness keys derived from one state’s rows do not hold for another, so keys are now widened against the national files too.

The legacy CCD years (1997-98 to 2013-14) are read from SAS files in 20,000-row chunks and written into the *same* tables as the modern years, with old codes recoded to the modern labels. The year suffixes are stripped only for files that use them, so a column like `G10` (grade 10) is not mangled.

### Missing is not zero

NCES marks missing, not-applicable and suppressed values with sentinel codes (`-1`, `-2`, `-3`, `-9`, or letters in some files). The pipeline turns these into NULL with a separate flag column that says why, so a suppressed count never shows up as zero on a chart. IPEDS is the exception: its negative codes are labelled categories in code columns, and finance values can legitimately be negative, so they are kept as published and documented in the caveats.

Sentinel handling has its own trap: Utah’s longitudes are negative. Coordinate columns are marked as signed in the maps after validation caught them being treated as missing.

### Getting every school onto the map

Coordinates come from four places, in order of preference:

1.  **NCES EDGE** files for public schools from 2014-15. The EDGE text files have no header row and their column order changes between years, so the pipeline reads the shapefile’s attribute table instead. A year that has a directory but no EDGE file yet carries each school’s latest coordinates forward.
2.  **CCD’s own coordinates** in the legacy files, available from 1999-00.
3.  **PSS and IPEDS** coordinates, where those surveys publish them (PSS from 2005-06, which is why the private-school layer starts there).
4.  The **Census Geocoder** for whatever is left. Results are cached in a committed Parquet file so they are never requested twice. The first run matched 146 of 163 addresses; non-exact matches get a dotted marker outline so approximate locations look approximate.

Private schools add a timing problem: the survey is biennial. For any slider year, the map shows the latest survey that began in or before it and says so.

### Deterministic output and a validation gate

Parquet output is written with explicit ordering, a single writer and fixed compression and row-group settings, so re-running `update` on unchanged inputs leaves `git status` clean. Every data change is a reviewable diff.

Validation also rejects row counts that fall more than 20% from the committed baseline, duplicate identifiers, files over 90 MB, columns without a dictionary entry and coordinates outside the state’s bounding box. That last check found a real exception: Navajo Mountain school sits just across the border in Arizona but is run by a Utah district. Rather than loosen the check, the state config lists that school’s ID as a known exception.

## 6 A state is a config file

Nothing in the code is specific to Utah. The state is set by one file:

``` yaml
name: Utah
abbrev: UT
fips: "49"
bbox: [-114.06, 36.99, -109.04, 42.01]   # [W, S, E, N]
center: [-111.65, 39.32]
zoom: 6
site_title: "Utah Education Explorer"
```

Validation fails if a state name shows up as a literal anywhere in the outputs, which is what keeps that promise honest. The Colorado smoke run built the modern CCD, EDGE, IPEDS and PSS data with no schema or type drift once the fixes above were in.

## 7 How it was built

I wrote the plan first, as a `HANDOFF.md` with the locked decisions (static hosting, no paid services, real NCES files rather than a third-party API, Utah as the target) and a phased plan, and built the project with Claude Code over a few days in October 2026. Every claim in the plan about URLs or columns was marked to be checked against the live source before use, and the first phase was nothing but spikes against real files. Several of the plan’s assumptions turned out wrong, the missing coordinates in the CCD directory among them, and those corrections are recorded in the repository’s `SPIKES.md` and `docs/DECISIONS.md`.

## 8 Limits and what’s next

- Not ingested: CCD 1986-87 to 1996-97 (fixed-width text only) and the 1997-98 district file. IPEDS tables before 2000 are in the table explorer but not on the map or in the charts.
- Some data stay in the Data tab only: PSS items whose layout changed between surveys, and the 2016-2020 faculty salary files, which report only total outlays and are left blank rather than guessed.
- Mobile layouts were tested in Chromium emulation only, and other browsers have not been tested.
- Larger states were not a design target. They should work in principle, but file sizes and browser memory have only been tested for Utah. The next step is a full Colorado build, including the legacy CCD years, and a look at size and load time for a large state.

The code is on [GitHub](https://github.com/ar-puuk/education-explorer) under the MIT license, and the README explains how to add a state. Education Explorer is archived on Zenodo with the DOI [10.5281/zenodo.23789925](https://doi.org/10.5281/zenodo.23789925).

## Citation

BibTeX citation:

``` quarto-appendix-bibtex
@software{bhandari2026,
  author = {Bhandari, Pukar},
  publisher = {Zenodo},
  title = {An {Education} {Explorer} for {Public} {NCES} {Data}},
  date = {2026-10-19},
  url = {https://ar-puuk.github.io/posts/education-explorer/},
  doi = {10.5281/zenodo.23789925},
  langid = {en-US}
}
```

For attribution, please cite this work as:

Bhandari, Pukar. 2026. *An Education Explorer for Public NCES Data*. Zenodo, released October 19. <https://doi.org/10.5281/zenodo.23789925>.
