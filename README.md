# Project Setup Guide

This project is a Quarto website that uses both **Python** and **R**. Because environment files and libraries are not synced to GitHub (to keep the repo clean), you must manually set up the local environments when you first download this project.

## 1. Prerequisites
Before starting, ensure you have the following installed:

* [Quarto CLI](https://quarto.org/docs/get-started/)
* [Miniconda](https://docs.anaconda.com/miniconda/) (for Python management)
* [R](https://cloud.r-project.org/) (latest version recommended)
* [Positron IDE](https://github.com/posit-dev/positron/releases) (or VS Code)

## 2. Clone the Repository
Open your terminal and clone the project:
```bash
git clone https://github.com/ar-puuk/ar-puuk.github.io.git
cd ar-puuk.github.io
```

## 3. Python Setup (Conda)
We use a local Conda environment located inside the project folder (`./env`). This folder is ignored by git, so you must recreate it.

1.  **Create the environment** from the configuration file:
    ```bash
    # This creates a folder named 'env' inside your project root
    conda env create --prefix ./env --file environment.yml
    ```

2.  **Activate the environment**:
    ```bash
    conda activate ./env
    ```

3.  **Set Environment Variables (Crucial for Windows)**:
    To prevent encoding errors (`UnicodeDecodeError`) with Python libraries, you must set this variable.
    * *Tip: You can make this permanent in your IDE settings.*
    ```powershell
    # Windows PowerShell
    $env:PYTHONUTF8 = "1"
    ```

## 4. R Setup (renv)
We use `renv` to manage R packages. The library folder is ignored by Git, so you must restore it.

1.  Open the project in **Positron** (or RStudio).
2.  Open the **R Console** and run:
    ```r
    if (!require("renv")) install.packages("renv")
    renv::restore()
    ```
    *This will download and compile all R packages listed in `renv.lock`.*

## 5. Configure Quarto Paths
This project uses an `_environment` file to tell Quarto where Python is. However, the default file contains paths specific to the original author's machine (e.g., `C:/Users/Pukar.Bhandari/...`).

1.  **Do not edit** the main `_environment` file (keeps git clean).
2.  **Create a new file** named `_environment.local` in the project root.
3.  Add the absolute path to your new local environment.

**Example `_environment.local` content:**
```bash
# Windows users: Note the forward slashes (/)
RETICULATE_PYTHON=C:/Users/YOUR_NAME/Documents/GitHub/ar-puuk.github.io/env/python.exe
QUARTO_PYTHON=C:/Users/YOUR_NAME/Documents/GitHub/ar-puuk.github.io/env/python.exe
PYTHONUTF8=1
```

## 6. Verify Installation
Run the Quarto check command to ensure it detects both engines correctly:

```bash
quarto check
```

* **Look for:** "Python 3 installation" pointing to your local `./env/python.exe`.
* **Look for:** "Jupyter engine render... OK".

## 7. Rendering the Site
To build the website locally:

```bash
quarto render
```
