# Project Setup Guide

This project is a Quarto website that uses both **Python** and **R**. Because environment files and libraries are not synced to GitHub (to keep the repo clean), you must manually set up the local environments when you first download this project.

## 1. Prerequisites
Before starting, ensure you have the following installed:

* [Quarto CLI](https://quarto.org/docs/get-started/)
* [uv](https://docs.astral.sh/uv/getting-started/installation/) (for Python management)
* [rig](https://github.com/r-lib/rig) (for installing and switching R versions)
* [R](https://cloud.r-project.org/) 4.6.1 or newer, installed through `rig`
* [Rtools](https://cran.r-project.org/bin/windows/Rtools/) (Windows only, for building R packages from source)
* [RStudio](https://posit.co/download/rstudio-desktop/) (or VS Code)

Install `uv` and `rig` on Windows (PowerShell):
```powershell
# uv
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# rig (alternatively, download the installer from https://github.com/r-lib/rig/releases)
winget install posit.rig
```

Install R and make it the default (run in a **new** terminal; `rig default` asks for administrator approval):
```powershell
rig add 4.6.1
rig default 4.6.1
Rscript --version   # should print 4.6.1
```
> Quarto and the shinylive extension call whichever `Rscript` is first on your `PATH`, so the default must be the same R version recorded in `renv.lock`.

## 2. Clone the Repository
Open your terminal and clone the project:
```bash
git clone https://github.com/ar-puuk/ar-puuk.github.io.git
cd ar-puuk.github.io
```

## 3. Python Setup (uv)
We use `uv` to manage Python versions and dependencies. The project contains a `pyproject.toml` and `uv.lock` file to guarantee reproducible environments.

1.  **Create the environment and install dependencies**:
    ```bash
    # This automatically downloads the correct Python version, creates a .venv folder, 
    # and installs all locked dependencies instantly.
    uv sync
    ```
    
    > (Windows Note: You may need to add `$env:PYTHONUTF8 = "1"` to your PowerShell profile to avoid encoding issues).

2.  **Activate the environment (Optional, for running scripts manually)**:
    ```bash
    # On Windows:
    .venv\Scripts\activate
    ```

## 4. R Setup (renv)
We use `renv` to manage R packages. The library folder is ignored by Git, so you must restore it.

1.  Open the project in **RStudio** (or VS Code).
2.  Open the **R Console** and run:
    ```r
    if (!require("renv")) install.packages("renv")
    renv::restore()
    ```
    *This installs all R packages listed in `renv.lock`.*

3.  **Package versions are pinned to a dated Posit Package Manager snapshot** (see `.Rprofile`), so installs get prebuilt Windows binaries and are reproducible. To update packages, change the date in `.Rprofile`, then run `renv::update()` and `renv::snapshot()`.

    > **If `renv::restore()` fails on `sedonadb`** (used only by `slides/spatial-benchmark`) with `DESCRIPTION file ... renv/staging/1/sedonadb/DESCRIPTION does not exist`, fix its record in `renv.lock`. It comes from r-universe, which only keeps its latest build, so it cannot be date-pinned, and `renv::snapshot()` records it with GitHub fields that renv cannot restore. Find the `"sedonadb": {` record and:
    >
    > 1. change `"Source": "unknown"` back to `"Source": "Repository"`, and
    > 2. delete the `RemoteType`, `RemoteUrl`, `RemoteRef`, `RemoteSha` and `RemoteSubdir` lines (and the trailing comma on the line above them).
    >
    > Then run `renv::restore()` again. You only need this after a snapshot has re-added those fields. Note that a plain `renv::snapshot()` refuses because of sedonadb's "unknown source"; use `renv::snapshot(force = TRUE)`. `renv::status()` reports sedonadb as out of sync even with the fixed record; that is harmless.
    >
    > If sedonadb itself later fails to install (r-universe moved on), build the version this site was benchmarked with from source (needs Rust, Rtools and libclang): `pak::pkg_install('apache/sedona-db/r/sedonadb@751453f')`.

    > Packages used only by Quarto extensions are loaded in a hidden chunk (e.g. `library(shinylive)` in `posts/storymap_my_journey/index.qmd`) so `renv::snapshot()` records them.

## 5. VS Code Settings (optional)
`.vscode/settings.json` points R and Quarto at R 4.6.1 and sets `R_LIBS` to the project's renv library for VS Code terminals. This lets Quarto extensions that call `Rscript` from a subfolder (such as shinylive) find the project packages.

Outside VS Code, set it yourself before rendering (PowerShell):

```powershell
$env:R_LIBS = (Resolve-Path "renv/library/windows/R-4.6/x86_64-w64-mingw32").Path
```

## 6. API Keys and Downloaded Data
Secrets and large downloads are not committed.

- **Census API key** (needed by `posts/socioeconomic-demo`): create a file named `_environment.local` in the project root containing `CENSUS_API_KEY=your_key`. Quarto loads it for both R and Python, and `.gitignore` excludes it. Get a free key at <https://www.census.gov/developers/>.
- **UGRC data** (Utah roads, bikeways, boundaries, address points): downloaded from UGRC's ArcGIS REST services the first time the post or slides are rendered, then reused. The first render of `posts/utah-bikeways` and `slides/spatial-benchmark` is therefore slow. The first full render of `slides/spatial-benchmark` also runs every benchmark (about 1.5M addresses), so expect it to take a while.

## 7. Verify Installation
Run the Quarto check command to ensure it detects both engines correctly:

```bash
quarto check
```

* **Look for:** "Python 3 installation" pointing to your local `.venv/Scripts/python.exe`.
* **Look for:** "Jupyter engine render... OK".

## 8. Rendering the Site
To build the website locally:

```bash
quarto render
```

Drafts: pages with `draft: true` are shown with a "Draft" banner because `draft-mode: visible` is set in `_quarto.yml`. Set it to `gone` to hide them (they become 404 pages and drop out of listings, search and the sitemap).

## 9. Publishing the Site
The built site (`docs/`) is not tracked in git. It is published to the `gh-pages` branch, which GitHub Pages serves (Settings > Pages > Deploy from a branch > `gh-pages` / root).

Render first, then publish what you just rendered:

```bash
quarto render
quarto publish gh-pages --no-render
```

* `--no-render` uploads the existing `docs/` as is. Without it, `quarto publish` renders the whole site again.
* Publishing goes live after a few minutes. Check `draft-mode` in `_quarto.yml` before you publish, since it decides whether `draft: true` pages go public.
* The first publish on a new clone needs the `gh-pages` branch to exist on the remote (it does now). Run the commands from a clone with push access.
* Source changes go to `master` as usual (`git add`, `git commit`, `git push`). `_freeze/` stays tracked so a re-render skips unchanged pages.
