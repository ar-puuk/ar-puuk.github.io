> **NOTE:**
>
> A fork of [Community Profiles](https://github.com/WFRCAnalytics/APP-Community-Profiles), which I developed at the [Wasatch Front Regional Council (WFRC)](https://wfrc.utah.gov/), hosted in my own repository with WFRC’s permission. The original belongs to WFRC ([details below](#the-original)). This app is still marked as a draft.

Utah’s population, housing, income, jobs and commuting figures come from several Census Bureau and Bureau of Labor Statistics sources (the American Community Survey, population estimates, LODES and QCEW), each with its own geographies and release schedule. Looking up “how has this county changed?” means piecing them together.

Demographic Profiles does that ahead of time and puts the result on a map, for the state, its counties and its cities and towns. A Python pipeline writes the data to Parquet files and the browser reads them directly, so there is no server behind it.

## Try it

Demographic Profiles

Fullscreen

[ Open app](https://ar-puuk.github.io/Demographic-Profiles/) [ GitHub](https://github.com/ar-puuk/Demographic-Profiles)

## What it does

Facts and figures for Utah, its counties and its cities and towns, all in one dashboard with no backend. Census tracts can be drawn on the maps.

- **ACS 5-year indicators** with trends from 2009 to 2024, annual population estimates, jobs, workers and commute flows from LODES, and employment and wages from QCEW.
- **Ten screens** from Overview to Commute, with a year slider that drives every panel, side-by-side comparison of two areas, and a shareable URL for any view.
- **Honest numbers:** every value carries a method label (published for exactly that area, or aggregated from whole Census blocks), so it is clear how a figure was produced.
- A **PDF report** (a designed profile or a poster) generated in the browser for any area.

## What I worked on

Everything in it. I developed the original at WFRC, both halves of it: the Python pipeline that downloads, validates and crosswalks the Census, LODES and QCEW data into committed Parquet files, and the Svelte and TypeScript front end that reads them in the browser with DuckDB-WASM, with MapLibre maps, Observable Plot charts and a Flowmap.gl commute layer. I authored all the commits in that repository.

This fork is mine to maintain. I reworked the geography from the WFRC region and its planning areas to the state, counties and cities and towns of Utah, and gave the app its own name and mark.

## The original: WFRC’s Community Profiles

Community Profiles is the WFRC app this one was derived from. It covers the WFRC region, its counties, cities and planning areas (AOG, MPO, RPO and workshop areas). It belongs to WFRC and is unchanged for now. WFRC allowed me to fork it and host this version in my own repository, with some adjustments, as a demographic profile. It will evolve to accommodate more diverse, strategic metrics for planning and regional development, such as population projections, land use characteristics, transit ridership and travel characteristics. Credit for the original, and for the Wasatch Front data work behind it, goes to the agency.

[ Community Profiles](https://wfrcanalytics.github.io/APP-Community-Profiles/) [ Its repository](https://github.com/WFRCAnalytics/APP-Community-Profiles) [ WFRC on GitHub](https://github.com/WFRCAnalytics) [ WFRC website](https://wfrc.utah.gov/)
