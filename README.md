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

    > `sedonadb` comes from r-universe, which only keeps its latest build, so it is not date-pinned. Its `renv.lock` record has the `Remote*` GitHub fields removed (they break `renv::restore()`), so `renv::status()` reports it as out of sync. This is harmless; `renv::snapshot()` re-adds the fields, so delete them again afterwards.

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
