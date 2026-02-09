# ═══════════════════════════════════════════════════════════════════════════════
# BENCHMARK 01: Legacy R Stack (sf + CSV/Shapefile)
# ═══════════════════════════════════════════════════════════════════════════════
# Purpose: Establish baseline performance using traditional R geospatial tools
#          and file formats (CSV for points, Shapefile for polygons)
#
# Strategy:
#   - Load all data into RAM (in-memory processing)
#   - Use sf package for spatial operations
#   - Standard point-in-polygon join with st_join()
#   - No explicit indexing (sf may use internal spatial index)
#
# Characteristics:
#   - Simple, straightforward workflow
#   - Works well for small to medium datasets
#   - Limited by available RAM
#   - Fast for datasets that fit in memory
#   - Industry-standard approach for R spatial analysis
#
# Limitations:
#   - Fails when data size exceeds available RAM
#   - No optimization for repeated queries
#   - File formats (CSV/SHP) are less efficient than Parquet
#
# Author: Pukar Bhandari
# Date: 2026-02-08
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────────
## 1. SETUP & CONFIGURATION ----
# ───────────────────────────────────────────────────────────────────────────────

library(sf) # Simple Features for R - standard geospatial package
library(dplyr) # Data manipulation
library(readr) # Fast CSV reading
library(bench) # High-precision benchmarking with memory tracking

# Define output path for benchmark results
results_csv <- "_results/benchmark_results.csv"

# Get iteration count from environment (set by run_all.R or index.qmd)
# Default to 1 if not set
ITERATIONS <- ifelse(exists("ITERATIONS"), ITERATIONS, 1)

# Helper function to log benchmark results to CSV
# Extracts median time and memory allocation from bench::mark object
log_result <- function(sys, lang, op, bm) {
  time_sec <- as.numeric(bm$median) # Median execution time
  mem_mb <- as.numeric(bm$mem_alloc) / 1024 / 1024 # Peak memory (MB)

  cat(
    sprintf("%s,%s,%s,%.4f,%.2f\n", sys, lang, op, time_sec, mem_mb),
    file = results_csv,
    append = TRUE
  )
}

# Define input file paths (legacy formats)
addr_csv <- "_data/utah_addresses.csv" # ~1.2M address points (CSV with x,y columns)
county_shp <- "_data/utah_counties.shp" # 29 county polygons (Shapefile)

message("────────────────────────────────────────────────────────────")
message("Running: BENCHMARK 01 - R (sf) Legacy Stack")
message("────────────────────────────────────────────────────────────")

# ───────────────────────────────────────────────────────────────────────────────
## 2. I/O BENCHMARK (Data Load) ----
# ───────────────────────────────────────────────────────────────────────────────
#
# This phase measures the cost of:
#   1. Reading CSV file with 1.2M address records
#   2. Converting x,y coordinates to sf POINT geometries
#   3. Reading Shapefile with 29 county polygons
#   4. Transforming both datasets to common CRS (EPSG:4326, WGS84)
#
# Note: All data is loaded into RAM. For datasets larger than available memory,
#       this approach will fail or cause system slowdown (swapping to disk).
#
# File Format Overhead:
#   - CSV: Row-based, no compression, no spatial awareness
#   - Shapefile: Multiple files (.shp, .shx, .dbf, .prj), limited to 2GB
# ───────────────────────────────────────────────────────────────────────────────

# Use bench::mark with iterations=1 to capture resource usage of a single run
bm_io <- bench::mark(
  load_data = {
    # ── A. Load Address Points from CSV ──
    # Read CSV and convert to sf object with POINT geometries
    pts <- read_csv(
      addr_csv,
      col_types = cols(CountyID = col_character()), # Preserve leading zeros
      show_col_types = FALSE
    ) |>
      st_as_sf(coords = c("x", "y"), crs = 4326) # Create geometry from x,y

    # ── B. Load County Polygons from Shapefile ──
    # Read Shapefile and transform to WGS84 (EPSG:4326)
    cnt <- st_read(county_shp, quiet = TRUE) |>
      st_transform(4326)
  },
  iterations = ITERATIONS, # Controlled by index.qmd or run_all.R
  check = FALSE # Skip bench::mark's equality checking
)

# Log the I/O benchmark result
log_result("sf", "R", "Load Data", bm_io)

# ───────────────────────────────────────────────────────────────────────────────
## 3. RELOAD DATA FOR ANALYSIS PHASE ----
# ───────────────────────────────────────────────────────────────────────────────
#
# bench::mark() runs in an isolated environment, so we need to reload the data
# for the subsequent analysis benchmark. This is not timed.
# ───────────────────────────────────────────────────────────────────────────────

# Re-load address points
pts <- read_csv(
  addr_csv,
  col_types = cols(CountyID = col_character()),
  show_col_types = FALSE
) |>
  st_as_sf(coords = c("x", "y"), crs = 4326)

# Re-load county polygons
cnt <- st_read(county_shp, quiet = TRUE) |>
  st_transform(4326)

# ───────────────────────────────────────────────────────────────────────────────
## 4. ANALYSIS BENCHMARK (Spatial Join) ----
# ───────────────────────────────────────────────────────────────────────────────
#
# This phase measures the performance of:
#   1. Attribute-based count (group by CountyID field)
#   2. Spatial join (point-in-polygon using st_join with st_within predicate)
#   3. Spatial count (group by county FIPS code from joined result)
#
# Spatial Join Logic:
#   - st_join() performs a point-in-polygon test for each address
#   - For each point, find which county polygon contains it
#   - Predicate: st_within — "is this point inside this polygon?"
#
# Performance Notes:
#   - sf may use an internal spatial index (STRtree via GEOS)
#   - All operations are in-memory (RAM intensive)
#   - For 1.2M points × 29 polygons, this can be fast if data fits in RAM
#
# Expected Performance:
#   - Fast for datasets under a few million records
#   - Slower or fails for very large datasets (>5M records on typical machines)
# ───────────────────────────────────────────────────────────────────────────────

bm_analysis <- bench::mark(
  validation = {
    # ── A. Attribute Count ──
    # Count addresses by their labeled CountyID attribute
    res_attr <- pts |>
      st_drop_geometry() |> # Remove geometry for faster aggregation
      count(CountyID)

    # ── B. Spatial Join ──
    # Join address points with county polygons based on spatial relationship
    # st_within: TRUE if point geometry is completely inside polygon geometry
    res_spatial <- st_join(pts, cnt, join = st_within) |>
      st_drop_geometry() |> # Remove geometry for faster aggregation
      count(FIPS_ST) # FIPS_ST is the county identifier from polygons
  },
  iterations = ITERATIONS, # Controlled by index.qmd or run_all.R
  check = FALSE # Disable bench::mark's comparison checks
)

# Log the spatial join benchmark result
log_result("sf", "R", "Validation (Join)", bm_analysis)

# ───────────────────────────────────────────────────────────────────────────────
## 5. CLEANUP ----
# ───────────────────────────────────────────────────────────────────────────────

# Remove large objects from memory (optional, but good practice)
rm(pts, cnt, res_attr, res_spatial)

message("────────────────────────────────────────────────────────────")
message("BENCHMARK 01 Complete!")
message("────────────────────────────────────────────────────────────")

# ═══════════════════════════════════════════════════════════════════════════════
# END OF BENCHMARK 01
# ═══════════════════════════════════════════════════════════════════════════════
