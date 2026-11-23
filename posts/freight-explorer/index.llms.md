The Freight Analysis Framework (FAF) is the go-to public source for how much freight moves between U.S. regions, by commodity and mode. It is also awkward to use: several releases with different zone systems, benchmark years and dollar bases, plus a forecast that skips 2025 to 2029. Answering “what moves in and out of Utah?” usually means downloading gigabytes and wrangling them yourself.

So I built an explorer that does the wrangling once and ships the result as a static site. Utah is the configured state; adding another is a one-file change. It is the second project in the same pattern as my [Education Explorer](../../posts/education-explorer/index.llms.md), and it reused that project’s conventions: a config file per state, a schema-drift guard, deterministic Parquet, and DuckDB running in the browser.

## 1 Try it

The live app is embedded below. Click a mode, commodity, partner state or year and every chart and the map follow.

FAF Freight Explorer

Fullscreen

This map needs JavaScript. The data behind it is in the [repository](https://github.com/ar-puuk/freight-explorer/tree/main/docs/data) as Parquet, GeoJSON and PMTiles files, and the sources and caveats are on the [methodology page](methodology.llms.md).

[ Open app](https://ar-puuk.github.io/freight-explorer/) [ Methodology](https://ar-puuk.github.io/freight-explorer/methodology.html) [ GitHub](https://github.com/ar-puuk/freight-explorer) [ DOI](https://doi.org/10.5281/zenodo.23789900)

## 2 Why FAF is awkward

FAF is published by the Bureau of Transportation Statistics (BTS) and the Federal Highway Administration, with Oak Ridge National Laboratory. The files are national CSVs: the FAF5.7.1 regional file alone is 1.18 GB, and the first pipeline run downloads about 2.5 GB. Then the differences between releases start:

- **Two generations, two zone systems.** FAF5.7.1 has 132 zones and a 2017 benchmark; FAF6.0 has 134 zones and a 2022 benchmark. Six zone IDs are shared by both but have different names.
- **Different measures.** FAF5 has tons, value and ton-miles, and current-dollar value only for 2018 to 2024. FAF6.0 has tons and value for a single year, 2022, and no ton-miles at all.
- **Gaps.** FAF5 has annual years to 2024 and then jumps to forecasts for 2030, 2035 and so on to 2050. Nothing exists for 2025 to 2029.
- **Wide files with explicit zeros.** Each year is a column, and a row exists if *any* year is positive, so more than a third of the rows in FAF5 are zero for a given year.

The two generations do not agree, either. For Utah in 2022, FAF5.7.1 puts domestic freight touching the state at 217,325 thousand tons and FAF6.0 at 329,980, about 52% more. National domestic tons are nearly equal in the two releases, so this is not a general rescale. Whatever the cause, it means the two can never share an axis, and that became one of the app’s firm rules.

## 3 A quick tour

- **Origin-destination flows** in tons, value and ton-miles for every record that touches the state, by commodity, mode and year. FAF5.7.1 (2017 to 2050) and FAF6.0 (2022) are kept apart, never combined on one axis.
- **Forecast scenarios**: the mid-range forecast plus FAF5’s published High and Low scenarios, with forecast and preliminary years marked and the unpublished 2025 to 2029 shown as a gap.
- **A timeline** that shows which years exist (benchmark, final, preliminary, forecast), hatches the missing years, and plays through published years only.
- **Linked charts instead of tables**: direction, mode and commodity (treemap), the largest partner states, trends with the scenario band, a commodity-by-year heat map, a two-year comparison, and a two-model comparison that puts FAF5 and FAF6 side by side with their own scales. Clicking any element filters everything else.
- **The FAF5 truck network** with modeled link volumes, a **FAF5-reprocessed state history** (1997, 2002, 2007 and 2012), and clearly labeled **experimental county-level estimates** for 2022.
- Search and jump with Ctrl K, keyboard shortcuts, a table with CSV export, and light, dark and color-blind-safe palettes. The whole view lives in the URL, so a link reproduces it.

> **IMPORTANT:**
>
> The app does not rank places, score performance, or present modeled values as measured counts. FAF flows are modeled estimates, and the app says so wherever they appear.

The interface follows a short list of rules written down in the repository’s design notes. Three of them do most of the work: *not published is never zero* (a missing measure shows “n/a” and why, and a control with no data stays visible but disabled with a reason), *a gap is data* (2025 to 2029 is hatched, never interpolated), and *models are never merged*.

## 4 How it works

Nothing runs on a server. A local pipeline turns the raw federal files into Parquet, GeoJSON and PMTiles, GitHub Pages serves them, and the browser queries them with DuckDB-WASM.

``` mermaid
flowchart LR
  A["BTS / FHWA / ORNL / Census files"] --> B["pipeline/<br>Python + DuckDB"]
  B -->|"validate"| C["Deterministic Parquet,<br>GeoJSON, PMTiles"]
  C --> D["GitHub Pages<br>docs/"]
  D --> E["Browser<br>DuckDB-WASM + MapLibre"]
```

The pipeline is a small command-line tool run with [uv](https://docs.astral.sh/uv/):

``` bash
cd pipeline
uv run python -m faf_pipeline update --state utah # <1>
uv run python -m faf_pipeline fetch --state utah --check-only # <2>
uv run python -m faf_pipeline validate --state utah # <3>
uv run pytest # <4>
```

1.  Fetch, build, zones, county estimates, network and validation in one go. It prints a changelog of what changed.
2.  Report changed files and new FAF releases without downloading anything.
3.  Run the checks that must pass before processed data is committed.
4.  Unit tests run on tiny fixture files for a fictional state.

Three design choices made the rest easy:

- **Deterministic output.** Re-running `update` on unchanged inputs produces byte-identical files, so a second run leaves no git diff and every data change is reviewable.
- **A schema guard.** Every downloaded file’s columns are checked against a column map, so a new release that renames or drops a column fails loudly instead of quietly corrupting results. A year that appears in a file but has not been classified as base, final, preliminary or forecast also stops the build.
- **No state literals in the code.** Utah appears only in `config/states/utah.yml`; validation fails if a state name, abbreviation or zone id shows up as a literal elsewhere.

## 5 The interesting problems

### GitHub Pages and range requests

Education Explorer relies on DuckDB-WASM reading only the byte ranges of a Parquet file that a query needs. I expected the same here, and the first spike showed it does not happen. On GitHub Pages, DuckDB-WASM fetched each Parquet file with one plain request, and the response came back gzip-compressed. Pages compresses on the fly, and a ranged request that also accepts gzip gets a slice of the *compressed* stream, with a `Content-Range` measured in compressed bytes. I did not pin down why the earlier project’s positive result did not reproduce, so the safe conclusion was not to rely on Parquet range reads on Pages at all. PMTiles range requests, made by the browser for the network layer, worked correctly.

Utah’s data is small, so the fix was to design for whole-file reads:

- Flows are partitioned into one small file per version, scenario and year (roughly 0.3 to 0.7 MB each).
- The first view draws from a 60-flow headline JSON file while DuckDB-WASM starts up, then the real query replaces it. Measured on the live site, the first arcs appear in about half a second.
- The roughly 11 MB of all-years data for FAF5.7.1 loads only when a Trends or Compare view needs it, and the timeline’s sparkline reads a small precomputed `year_totals.json` instead.

### Where should an arc start?

A flow map needs one point per zone. The obvious choice, a point inside the zone polygon, put Utah’s Salt Lake zone in the Tooele County desert, west of the city, and every arc started there. The fix uses the Census 2020 county centers of population: each zone’s anchor is the population-weighted mean of the county centers inside it, falling back to the most populous county center, and then to a point on the polygon. The method used is stored for every zone. The Salt Lake zone now anchors in the Salt Lake Valley.

### Checking FAF against itself

FAF publishes the same flows at more than one level, and that makes good tests. The state-level file turned out to be exactly the regional file aggregated to states, with zero mismatched rows for both FAF5.7.1 and FAF6.0, so validation reconciles the two for every year and scenario at a tolerance of one millionth. The High/Low scenario files repeat the mid-range columns, and the build checks that they equal the mid-range files already written.

The experimental county product was harder. It is tons only, uses five commodity groups instead of 42, and has a mode code, `11`, that is not in FAF’s list. BTS pages refuse scripted requests, so I found the technical report through a Wayback Machine snapshot; it defines `11` as truck and air combined. With that, the state-touching rows of the county tables sum to *exactly* FAF5.7.1’s 2022 domestic tons for Utah, mode by mode, and validation fails if any mode drifts more than 1% apart. Import and export totals still differ slightly, for reasons I have not established, and the methodology page says so.

### A truck network without tippecanoe

The FAF5 network has 487,394 links. The pipeline clips it to Utah plus a 25 km buffer (computed in a local projection centred on the state, so it would also work for Alaska or Hawaii) and writes PMTiles directly with DuckDB’s spatial extension, about 2.4 MB, with no tippecanoe or GDAL command-line tools. In the browser, link volumes from a Parquet file are joined to the tiles with MapLibre feature-state. One surprise: the busiest truck link near Utah in 2017 was a *centroid connector*, a virtual link that connects a zone to the network. Connectors stay in the data but are hidden on the map by default.

### When the basemap does not load

Testing with the basemap host blocked showed the app silently stopped before starting its query engine, because map operations ran before any style existed. Now, if the style fails or takes longer than ten seconds, the map switches to a plain background and flows, zones and the network keep working. Two details took some finding: the deck.gl overlay must receive its first layers before the style loads (holding them back stalls the map), and MapLibre’s `error` event also fires for a single failed tile or glyph, so only a style that never loads triggers the fallback.

A related lesson: building the map and the methodology page in one multi-page Vite build changed the chunk layout enough that the MapLibre and deck.gl WebGL contexts were lost at load. The two pages are now built separately.

### A second state

To test the “one config file” claim, I ran the same code once for Colorado in a scratch copy. It needed one fix: the literal check flagged Colorado’s FIPS code `08` because `08` is also a commodity code, so FIPS codes are now checked only in code files. The county estimates again matched FAF5.7.1’s 2022 domestic tons by mode exactly. Utah remains the only supported state.

## 6 Stack

| Layer    | Tools                                  |
|----------|----------------------------------------|
| Pipeline | Python, DuckDB, uv, pytest             |
| App      | Vite, Svelte 5, TypeScript             |
| Maps     | MapLibre, deck.gl, flowmap.gl, PMTiles |
| Queries  | DuckDB-WASM over Parquet               |
| Charts   | Observable Plot                        |

Basemaps come from OpenFreeMap, and a content-security policy restricts the page to its own files and OpenFreeMap. Fonts are bundled for the same reason.

## 7 How it was built

As with Education Explorer, I wrote the plan as a `HANDOFF.md` (locked decisions, data landscape, phased plan) and built the project with Claude Code. Every URL, column name and unit in the plan was marked to be verified against the real files, and the first phase was spikes only. The plan was wrong in a dozen places, from FAF6’s missing ton-miles to the range-request behaviour above, and the corrections are recorded in `docs/SPIKES.md` and `docs/DECISIONS.md`. A full interface redesign followed the first complete version, rebuilding the presentation around the map, linked charts and the timeline while leaving the data and pipeline untouched.

## 8 Limits and what’s next

- FAF6.0 has a single year and no ton-miles; FAF5 has no 2025 to 2029; High and Low have tons and value only. When BTS adds FAF6 annual years or ton-miles, the schema already maps those columns and the app discovers them from the data.
- The network flows are a FAF5.3-era model assignment, not traffic counts and not updated to FAF5.7.1 or FAF6.
- The FAF6 constant-dollar year (2022) is taken from the release notes and was not independently verified. The eight foreign regions are drawn at schematic positions.
- Testing so far is headless Chromium with automated accessibility checks. Firefox, Safari, a real GPU, real phones and a screen reader have not been tried.

The [methodology page](https://ar-puuk.github.io/freight-explorer/methodology.html) lists every source file, release and caveat. The code is on [GitHub](https://github.com/ar-puuk/freight-explorer) under the MIT license; issues and PRs are welcome. Freight Explorer is archived on Zenodo with the DOI [10.5281/zenodo.23789900](https://doi.org/10.5281/zenodo.23789900).

## Citation

BibTeX citation:

``` quarto-appendix-bibtex
@software{bhandari2026,
  author = {Bhandari, Pukar},
  publisher = {Zenodo},
  title = {A {Zero-Cost} {Freight} {Flow} {Explorer} for {Utah}},
  date = {2026-10-19},
  url = {https://ar-puuk.github.io/posts/freight-explorer/},
  doi = {10.5281/zenodo.23789900},
  langid = {en-US}
}
```

For attribution, please cite this work as:

Bhandari, Pukar. 2026. *A Zero-Cost Freight Flow Explorer for Utah*. Zenodo, released October 19. <https://doi.org/10.5281/zenodo.23789900>.
