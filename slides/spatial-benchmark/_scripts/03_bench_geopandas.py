# ═══════════════════════════════════════════════════════════════════════════════
# BENCHMARK 03: Legacy Python Stack (GeoPandas + CSV/Shapefile)
# ═══════════════════════════════════════════════════════════════════════════════
# Purpose: Establish baseline performance using traditional Python geospatial
#          tools and file formats (CSV for points, Shapefile for polygons)
#
# FIX NOTES (vs. original):
#
#   FIX 1 — Honest memory measurement via psutil RSS:
#     tracemalloc only tracks Python-managed allocations. GeoPandas uses
#     shapely geometries backed by GEOS (C library), which allocates in a
#     separate arena that tracemalloc cannot see. For 1.2M address points,
#     GEOS geometry objects can consume 300–500 MB of C-heap memory that
#     tracemalloc reports as zero. psutil.Process().memory_info().rss
#     captures the true process resident set size.
#
# Author: Pukar Bhandari
# ═══════════════════════════════════════════════════════════════════════════════

import os
import sys
import time
import statistics
import pandas as pd
import geopandas as gpd
import psutil       # FIX 1
from pathlib import Path

ITERATIONS = int(os.environ.get('BENCHMARK_ITERATIONS', '1'))

if os.name == 'nt':
    gdal_data_path = Path(sys.prefix) / "Library" / "share" / "gdal"
    if gdal_data_path.exists():
        os.environ['GDAL_DATA'] = str(gdal_data_path)

RESULTS_CSV = "_results/benchmark_results.csv"
ADDR_CSV    = "_data/utah_addresses.csv"
COUNTY_SHP  = "_data/utah_counties.shp"

def log_result(sys_name, lang, op, time_sec, peak_mem_mb):
    with open(RESULTS_CSV, "a") as f:
        f.write(f"{sys_name},{lang},{op},{time_sec:.4f},{peak_mem_mb:.2f}\n")

# FIX 1: RSS-based memory measurement
proc = psutil.Process(os.getpid())

def rss_mb():
    return proc.memory_info().rss / 1024 / 1024

print("─" * 60)
print("Running: BENCHMARK 03 - Python (GeoPandas) Legacy Stack")
print("─" * 60)

# ───────────────────────────────────────────────────────────────────────────────
## 2. I/O BENCHMARK (Data Load) ----
# ───────────────────────────────────────────────────────────────────────────────

load_times = []
load_mems  = []

for _ in range(ITERATIONS):
    mem_before = rss_mb()
    t_start    = time.perf_counter()

    df = pd.read_csv(ADDR_CSV, dtype={"CountyID": str}, low_memory=False)
    pts = gpd.GeoDataFrame(
        df,
        geometry=gpd.points_from_xy(df.x, df.y),
        crs="EPSG:4326"
    )
    cnt = gpd.read_file(COUNTY_SHP).to_crs("EPSG:4326")

    load_times.append(time.perf_counter() - t_start)
    load_mems.append(rss_mb() - mem_before)

log_result("geopandas", "Python", "Load Data",
           statistics.median(load_times),
           max(load_mems))
print(f"  Load Data: {statistics.median(load_times):.3f}s | {max(load_mems):.1f} MB RSS delta")

# ───────────────────────────────────────────────────────────────────────────────
## 3. ANALYSIS BENCHMARK (Spatial Join) ----
# ───────────────────────────────────────────────────────────────────────────────

# Load data once outside the timed loop (same pattern as 01_bench_sf.R)
df  = pd.read_csv(ADDR_CSV, dtype={"CountyID": str}, low_memory=False)
pts = gpd.GeoDataFrame(df, geometry=gpd.points_from_xy(df.x, df.y), crs="EPSG:4326")
cnt = gpd.read_file(COUNTY_SHP).to_crs("EPSG:4326")

join_times = []
join_mems  = []

for _ in range(ITERATIONS):
    mem_before = rss_mb()
    t_start    = time.perf_counter()

    res_attr    = pts.groupby("CountyID").size()
    joined      = gpd.sjoin(pts, cnt, how="inner", predicate="within")
    res_spatial = joined.groupby("FIPS_ST").size()

    join_times.append(time.perf_counter() - t_start)
    join_mems.append(rss_mb() - mem_before)

log_result("geopandas", "Python", "Validation (Join)",
           statistics.median(join_times),
           max(join_mems))
print(f"  Validation (Join): {statistics.median(join_times):.3f}s | {max(join_mems):.1f} MB RSS delta")

# ───────────────────────────────────────────────────────────────────────────────
## 4. CLEANUP ----
# ───────────────────────────────────────────────────────────────────────────────

del pts, cnt, joined, res_attr, res_spatial

print("─" * 60)
print("BENCHMARK 03 Complete!")
print("─" * 60)
