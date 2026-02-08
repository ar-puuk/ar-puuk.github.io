import os
import sys
import time
import tracemalloc
import pandas as pd
import geopandas as gpd
from pathlib import Path

if os.name == 'nt':
    # In Conda on Windows, GDAL data is usually at <env>/Library/share/gdal
    gdal_data_path = Path(sys.prefix) / "Library" / "share" / "gdal"
    if gdal_data_path.exists():
        os.environ['GDAL_DATA'] = str(gdal_data_path)

RESULTS_CSV = "_results/benchmark_results.csv"

def log_result(sys, lang, op, time_sec, peak_mem_mb):
    with open(RESULTS_CSV, "a") as f:
        f.write(f"{sys},{lang},{op},{time_sec:.4f},{peak_mem_mb:.2f}\n")

ADDR_CSV = "_data/utah_addresses.csv"
COUNTY_SHP = "_data/utah_counties.shp"

print("--- 03: Python (GeoPandas) Legacy ---")

# 1. I/O Benchmark
tracemalloc.start()
start = time.perf_counter()

df = pd.read_csv(ADDR_CSV, dtype={"CountyID": str}, low_memory=False)
pts = gpd.GeoDataFrame(df, geometry=gpd.points_from_xy(df.x, df.y), crs="EPSG:4326")
cnt = gpd.read_file(COUNTY_SHP).to_crs("EPSG:4326")

end = time.perf_counter()
current, peak = tracemalloc.get_traced_memory()
tracemalloc.stop()
log_result("geopandas", "Python", "Load Data", end - start, peak / 1024 / 1024)

# 2. Analysis Benchmark
tracemalloc.start()
start = time.perf_counter()

# Attribute Count
res_attr = pts.groupby("CountyID").size()
# Spatial Join
joined = gpd.sjoin(pts, cnt, how="inner", predicate="within")
res_spatial = joined.groupby("FIPS_ST").size()

end = time.perf_counter()
current, peak = tracemalloc.get_traced_memory()
tracemalloc.stop()
log_result("geopandas", "Python", "Validation (Join)", end - start, peak / 1024 / 1024)
