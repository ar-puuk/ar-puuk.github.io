# ═══════════════════════════════════════════════════════════════════════════════
# SETUP DATA: Download, convert, and verify prerequisites
# ═══════════════════════════════════════════════════════════════════════════════
# FIX (vs previous version):
#   Module D previously checked for Java, sparklyr, and apache.sedona — those
#   are requirements for the Spark-based Apache Sedona, NOT for the sedonadb
#   community package. sedonadb is an embedded Rust/DataFusion engine with no
#   JVM dependency whatsoever. Module D is replaced with a simple package
#   availability check and smoke test.
# ═══════════════════════════════════════════════════════════════════════════════

library(arcgislayers)
library(sf)
library(arrow)
library(geoarrow)
library(dplyr)
library(readr)
library(tibble)
library(duckdb)
library(DBI)

data_dir <- "_data"
if (!dir.exists(data_dir)) {
  dir.create(data_dir)
}

# --- File Paths ---

addr_parquet <- file.path(data_dir, "utah_addresses.parquet")
addr_csv <- file.path(data_dir, "utah_addresses.csv")
county_parquet <- file.path(data_dir, "utah_counties.parquet")
county_shp <- file.path(data_dir, "utah_counties.shp")

# --- MODULE A: UTAH ADDRESS POINTS (~1.2M records) ---

if (!file.exists(addr_parquet) || !file.exists(addr_csv)) {
  message("Address data missing or incomplete. Downloading from UGRC...")

  addr_url <- "https://services1.arcgis.com/99lidPhWCzftIe9K/ArcGIS/rest/services/UtahAddressPoints/FeatureServer/0"

  utah_addresses <- addr_url |>
    arcgislayers::arc_open() |>
    arcgislayers::arc_select(crs = 4326)

  message("Exporting Address Points to CSV...")
  utah_addresses |>
    dplyr::mutate(
      x = sf::st_coordinates(geometry)[, 1],
      y = sf::st_coordinates(geometry)[, 2]
    ) |>
    sf::st_drop_geometry() |>
    readr::write_csv(addr_csv, append = FALSE)

  message("Exporting Address Points to GeoParquet...")
  utah_addresses |>
    tibble::as_tibble() |>
    dplyr::mutate(geometry = sf::st_as_binary(geometry) |> unclass()) |>
    arrow::write_parquet(addr_parquet)

  rm(utah_addresses)
} else {
  message("Success: All Address Point formats (CSV/Parquet) found locally.")
}

# --- MODULE B: UTAH COUNTY BOUNDARIES ---

if (!file.exists(county_parquet) || !file.exists(county_shp)) {
  message("County data missing or incomplete. Downloading from UGRC...")

  county_url <- "https://services1.arcgis.com/99lidPhWCzftIe9K/ArcGIS/rest/services/UtahCountyBoundaries/FeatureServer/0"

  utah_counties <- county_url |>
    arcgislayers::arc_open() |>
    arcgislayers::arc_select(crs = 4326)

  message("Exporting County Boundaries to SHP...")
  utah_counties |>
    sf::st_write(county_shp, delete_dsn = TRUE, quiet = TRUE)

  message("Exporting County Boundaries to GeoParquet...")
  utah_counties |>
    tibble::as_tibble() |>
    dplyr::mutate(geometry = sf::st_as_binary(geometry) |> unclass()) |>
    arrow::write_parquet(county_parquet)
} else {
  message("Success: All County Boundary formats (SHP/Parquet) found locally.")
}

# --- MODULE C: PRE-INSTALL DUCKDB SPATIAL EXTENSION (once) ---
#
# Install the DuckDB spatial extension here so benchmark scripts can
# use LOAD spatial (fast, no network check) rather than INSTALL spatial
# (slow, makes a network version-check every time). INSTALL is idempotent.

message("Pre-installing DuckDB spatial extension (if not already cached)...")
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL spatial;")
dbExecute(con, "LOAD spatial;")
dbDisconnect(con)
message("DuckDB spatial extension ready.")

# --- MODULE D: VERIFY SEDONADB PACKAGE ---
#
# FIX: sedonadb (from community.r-multiverse.org) is an EMBEDDED Rust/DataFusion
# engine — it has NO Java dependency, NO Spark requirement, NO JVM.
# The previous version of this module incorrectly checked for Java, sparklyr,
# and apache.sedona (requirements for the Spark-based Apache Sedona, a
# completely different package). Those checks are removed entirely.

message("Verifying sedonadb package...")

if (!requireNamespace("sedonadb", quietly = TRUE)) {
  stop(
    "sedonadb package not found. Install it with:\n",
    "  install.packages('sedonadb', repos = 'https://community.r-multiverse.org')"
  )
}

library(sedonadb)

# Smoke test: verify spatial SQL functions are accessible
tryCatch(
  {
    test_result <- sd_sql("SELECT ST_Point(1.0, 2.0) AS geom") |> sd_collect()
    stopifnot(nrow(test_result) == 1L)
    message("sedonadb ready. Spatial functions verified.")
  },
  error = function(e) {
    stop(
      "sedonadb loaded but spatial functions failed. Error:\n",
      conditionMessage(e),
      "\n",
      "Try reinstalling: install.packages('sedonadb', repos = 'https://community.r-multiverse.org')"
    )
  }
)

message("Setup Phase Finished. Files verified in: ", data_dir)
