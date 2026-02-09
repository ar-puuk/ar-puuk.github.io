# ═══════════════════════════════════════════════════════════════════════════════
# BENCHMARK 03: Legacy Python Stack (GeoPandas + CSV/Shapefile)
# ═══════════════════════════════════════════════════════════════════════════════
# Purpose: Establish baseline performance using traditional Python geospatial
#          tools and file formats (CSV for points, Shapefile for polygons)
#
# Strategy:
#   - Load all data into RAM (in-memory processing)
#   - Use GeoPandas (built on pandas + shapely) for spatial operations
#   - Standard point-in-polygon join with gpd.sjoin()
#   - Implicit spatial indexing (GeoPandas uses STRtree automatically)
#
# Characteristics:
#   - Pythonic API, familiar to pandas users
#   - Works well for small to medium datasets
#   - Limited by available RAM
#   - Fast spatial joins via automatic STRtree indexing
#   - Industry-standard approach for Python spatial analysis
#
# Limitations:
#   - Fails when data size exceeds available RAM
#   - No optimization for repeated queries
#   - File formats (CSV/SHP) are less efficient than Parquet
#   - High memory consumption for large datasets
#
# Author: Pukar Bhandari
# Date: 2026-02-08
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────────
## 1. SETUP & CONFIGURATION ----
# ───────────────────────────────────────────────────────────────────────────────

import os
import sys
import time
import tracemalloc
import pandas as pd
import geopandas as gpd
from pathlib import Path

# Get iteration count from environment variable (set by run_all.R)
# Default to 1 if not set
ITERATIONS = int(os.environ.get('BENCHMARK_ITERATIONS', '1'))

# Handle Windows GDAL configuration
# GDAL is the underlying library for reading/writing geospatial formats
if os.name == 'nt':
    # In Conda on Windows, GDAL data is usually at <env>/Library/share/gdal
    gdal_data_path = Path(sys.prefix) / "Library" / "share" / "gdal"
    if gdal_data_path.exists():
        os.environ['GDAL_DATA'] = str(gdal_data_path)

# Define output path for benchmark results
RESULTS_CSV = "_results/benchmark_results.csv"

def log_result(sys_name, lang, op, time_sec, peak_mem_mb):
    """
    Log benchmark results to CSV file.

    Args:
        sys_name: System name (e.g., 'geopandas')
        lang: Language (e.g., 'Python')
        op: Operation name (e.g., 'Load Data')
        time_sec: Execution time in seconds
        peak_mem_mb: Peak memory usage in megabytes
    """
    with open(RESULTS_CSV, "a") as f:
        f.write(f"{sys_name},{lang},{op},{time_sec:.4f},{peak_mem_mb:.2f}\n")

# Define input file paths (legacy formats)
ADDR_CSV = "_data/utah_addresses.csv"      # ~1.2M address points (CSV with x,y)
COUNTY_SHP = "_data/utah_counties.shp"     # 29 county polygons (Shapefile)

print("─" * 60)
print("Running: BENCHMARK 03 - Python (GeoPandas) Legacy Stack")
print("─" * 60)

# ───────────────────────────────────────────────────────────────────────────────
## 2. I/O BENCHMARK (Data Load) ----
# ───────────────────────────────────────────────────────────────────────────────
#
# This phase measures the cost of:
#   1. Reading CSV file with 1.2M address records
#   2. Converting x,y coordinates to shapely POINT geometries
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

# Start memory and time tracking
tracemalloc.start()
start_time = time.perf_counter()

# Run the load operation ITERATIONS times and take the median
for _ in range(ITERATIONS):
    # ── A. Load Address Points from CSV ──
    # Read CSV with pandas, ensuring CountyID is treated as string (preserve leading zeros)
    df = pd.read_csv(ADDR_CSV, dtype={"CountyID": str}, low_memory=False)

    # Convert to GeoDataFrame by creating POINT geometries from x,y columns
    pts = gpd.GeoDataFrame(
        df,
        geometry=gpd.points_from_xy(df.x, df.y),  # Create Point geometries
        crs="EPSG:4326"                           # Set coordinate reference system
    )

    # ── B. Load County Polygons from Shapefile ──
    # Read Shapefile and transform to WGS84 (EPSG:4326)
    cnt = gpd.read_file(COUNTY_SHP).to_crs("EPSG:4326")

# Stop timing and memory tracking
end_time = time.perf_counter()
current_mem, peak_mem = tracemalloc.get_traced_memory()
tracemalloc.stop()

# Log the I/O benchmark result
log_result("geopandas", "Python", "Load Data",
           end_time - start_time,
           peak_mem / 1024 / 1024)

# ───────────────────────────────────────────────────────────────────────────────
## 3. ANALYSIS BENCHMARK (Spatial Join) ----
# ───────────────────────────────────────────────────────────────────────────────
#
# This phase measures the performance of:
#   1. Attribute-based count (group by CountyID field)
#   2. Spatial join (point-in-polygon using gpd.sjoin with "within" predicate)
#   3. Spatial count (group by county FIPS code from joined result)
#
# Spatial Join Logic:
#   - gpd.sjoin() performs a point-in-polygon test for each address
#   - For each point, find which county polygon contains it
#   - Predicate: "within" — "is this point inside this polygon?"
#
# Performance Notes:
#   - GeoPandas automatically builds an STRtree spatial index internally
#   - This implicit indexing makes spatial joins fast (O(n log m) vs O(n*m))
#   - STRtree is built on-the-fly during sjoin() execution
#   - All operations are in-memory (RAM intensive)
#
# Expected Performance:
#   - Fast spatial joins due to automatic STRtree indexing
#   - For 1.2M points × 29 polygons, typically 5-15 seconds
#   - High memory consumption (~1.5 GB for this dataset)
# ───────────────────────────────────────────────────────────────────────────────

# Start memory and time tracking for analysis phase
tracemalloc.start()
start_time = time.perf_counter()

# Run the analysis operation ITERATIONS times
for _ in range(ITERATIONS):
    # ── A. Attribute Count ──
    # Count addresses by their labeled CountyID attribute
    res_attr = pts.groupby("CountyID").size()

    # ── B. Spatial Join ──
    # Join address points with county polygons based on spatial relationship
    # - how="inner": Keep only points that fall inside a polygon
    # - predicate="within": Point must be completely inside polygon
    # - GeoPandas builds STRtree index automatically for efficient lookup
    joined = gpd.sjoin(pts, cnt, how="inner", predicate="within")

    # Count addresses by actual spatial location (from joined county FIPS code)
    res_spatial = joined.groupby("FIPS_ST").size()

# Stop timing and memory tracking
end_time = time.perf_counter()
current_mem, peak_mem = tracemalloc.get_traced_memory()
tracemalloc.stop()

# Log the spatial join benchmark result
log_result("geopandas", "Python", "Validation (Join)",
           end_time - start_time,
           peak_mem / 1024 / 1024)

# ───────────────────────────────────────────────────────────────────────────────
## 4. CLEANUP ----
# ───────────────────────────────────────────────────────────────────────────────

# Python's garbage collector will handle cleanup, but explicit deletion
# can help free memory faster for large datasets
del pts, cnt, joined, res_attr, res_spatial

print("─" * 60)
print("BENCHMARK 03 Complete!")
print("─" * 60)

# ═══════════════════════════════════════════════════════════════════════════════
# END OF BENCHMARK 03
# ═══════════════════════════════════════════════════════════════════════════════
