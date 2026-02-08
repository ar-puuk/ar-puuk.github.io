# --- SETUP & LIBRARIES ---

# 1. Package Installation (uncomment if running on a new machine)
# install.packages(c("arcgislayers", "sf", "arrow", "geoarrow", "dplyr", "readr", "tibble"))

# 2. Load Libraries
library(arcgislayers) # Interfaces with ArcGIS REST APIs
library(sf) # Standard for spatial data handling in R
library(arrow) # engine for Parquet files
library(geoarrow) # Extension for GeoParquet support (v0.4.1)
library(dplyr) # Data manipulation
library(readr) # High-performance CSV writing
library(tibble)

# 3. Define Paths (Relative to CWD, which run_all.sh sets to 'spatial-benchmark/')
data_dir <- "_data"
if (!dir.exists(data_dir)) {
  dir.create(data_dir)
}

# --- 2. MODULAR DATA INGESTION ---

# Define target file paths for easier checking
addr_parquet <- file.path(data_dir, "utah_addresses.parquet")
addr_csv <- file.path(data_dir, "utah_addresses.csv")
county_parquet <- file.path(data_dir, "utah_counties.parquet")
county_shp <- file.path(data_dir, "utah_counties.shp")

# --- MODULE A: UTAH ADDRESS POINTS (~1.2M records) ---
# Logic: Download if either the Parquet OR the CSV is missing
if (!file.exists(addr_parquet) || !file.exists(addr_csv)) {
  message("Address data missing or incomplete. Downloading from UGRC...")

  addr_url <- "https://services1.arcgis.com/99lidPhWCzftIe9K/ArcGIS/rest/services/UtahAddressPoints/FeatureServer/0"

  utah_addresses <- addr_url |>
    arcgislayers::arc_open() |>
    arcgislayers::arc_select(crs = 4326)

  # Export to CSV (Legacy)
  message("Exporting Address Points to CSV...")
  utah_addresses |>
    dplyr::mutate(
      x = sf::st_coordinates(geometry)[, 1],
      y = sf::st_coordinates(geometry)[, 2]
    ) |>
    sf::st_drop_geometry() |>
    readr::write_csv(addr_csv, append = FALSE)

  # Export to GeoParquet (Modern)
  message("Exporting Address Points to GeoParquet...")
  # Export Parquet (Convert to WKB Binary for DuckDB)
  utah_addresses |>
    tibble::as_tibble() |>
    dplyr::mutate(geometry = sf::st_as_binary(geometry) |> unclass()) |>
    arrow::write_parquet(addr_parquet)

  rm(utah_addresses) # Clear memory after large download
} else {
  message("Success: All Address Point formats (CSV/Parquet) found locally.")
}

# --- MODULE B: UTAH COUNTY BOUNDARIES ---
# Logic: Download if either the Parquet OR the SHP is missing
if (!file.exists(county_parquet) || !file.exists(county_shp)) {
  message("County data missing or incomplete. Downloading from UGRC...")

  county_url <- "https://services1.arcgis.com/99lidPhWCzftIe9K/ArcGIS/rest/services/UtahCountyBoundaries/FeatureServer/0"

  utah_counties <- county_url |>
    arcgislayers::arc_open() |>
    arcgislayers::arc_select(crs = 4326)

  # Export to Shapefile (Legacy)
  message("Exporting County Boundaries to SHP...")
  utah_counties |>
    sf::st_write(
      county_shp,
      delete_dsn = TRUE,
      quiet = TRUE
    )

  # Export to GeoParquet (Modern)
  message("Exporting County Boundaries to GeoParquet...")
  utah_counties |>
    tibble::as_tibble() |>
    dplyr::mutate(geometry = sf::st_as_binary(geometry) |> unclass()) |>
    arrow::write_parquet(county_parquet)
} else {
  message("Success: All County Boundary formats (SHP/Parquet) found locally.")
}

message("Setup Phase Finished. Files verified in: ", data_dir)
