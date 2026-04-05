# Project Setup Guide

This project is a Quarto website that uses both **Python** and **R**. Because environment files and libraries are not synced to GitHub (to keep the repo clean), you must manually set up the local environments when you first download this project.

## 1. Prerequisites
Before starting, ensure you have the following installed:

* [Quarto CLI](https://quarto.org/docs/get-started/)
* [uv](https://docs.astral.sh/uv/getting-started/installation/) (for Python management)
* [R](https://cloud.r-project.org/) (latest version recommended)
* [RStudio](https://posit.co/download/rstudio-desktop/) (or VS Code)

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
    *This will download and compile all R packages listed in `renv.lock`.*


## 6. Verify Installation
Run the Quarto check command to ensure it detects both engines correctly:

```bash
quarto check
```

* **Look for:** "Python 3 installation" pointing to your local `.venv/Scripts/python.exe`.
* **Look for:** "Jupyter engine render... OK".

## 7. Rendering the Site
To build the website locally:

```bash
quarto render
```
