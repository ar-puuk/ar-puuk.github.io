# ═══════════════════════════════════════════════════════════════════════════════
# BENCHMARK 04: Modern Python Stack (DuckDB + Parquet + Spatial Index)
# ═══════════════════════════════════════════════════════════════════════════════
# Purpose: Demonstrate DuckDB's efficiency for large-scale spatial operations
#          using columnar storage (Parquet) and dual spatial indexing (RTREE)
#
# Strategy:
#   - Load data from Parquet files (compressed, typed, columnar)
#   - Build RTREE spatial indexes on BOTH points and polygons
#   - Use explicit JOIN syntax for query optimization
#   - Separate index creation (I/O) from query execution (Analysis)
#
# Key Advantages:
#   - Out-of-core processing (handles data larger than RAM)
#   - Dual indexing accelerates spatial predicates
#   - Index once, query many times
#   - Portable SQL logic (same query works in R)
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
import duckdb
from pathlib import Path

# Get iteration count from environment variable (set by run_all.R)
# Default to 1 if not set
ITERATIONS = int(os.environ.get('BENCHMARK_ITERATIONS', '1'))

# Handle Windows GDAL configuration (for some Python geospatial libraries)
# Note: DuckDB's spatial extension doesn't need this, but keeping for compatibility
if os.name == 'nt':
    gdal_data_path = Path(sys.prefix) / "Library" / "share" / "gdal"
    if gdal_data_path.exists():
        os.environ['GDAL_DATA'] = str(gdal_data_path)

# Define output path for benchmark results
RESULTS_CSV = "_results/benchmark_results.csv"

def log_result(sys_name, lang, op, time_sec, peak_mem_mb):
    """
    Log benchmark results to CSV file.

    Args:
        sys_name: System name (e.g., 'duckdb')
        lang: Language (e.g., 'Python')
        op: Operation name (e.g., 'Load Data')
        time_sec: Execution time in seconds
        peak_mem_mb: Peak memory usage in megabytes
    """
    with open(RESULTS_CSV, "a") as f:
        f.write(f"{sys_name},{lang},{op},{time_sec:.4f},{peak_mem_mb:.2f}\n")

# Define input file paths (Parquet format with WKB-encoded geometries)
ADDR_PQ = "_data/utah_addresses.parquet"   # ~1.2M address points
COUNTY_PQ = "_data/utah_counties.parquet"  # 29 county polygons

print("─" * 60)
print("Running: BENCHMARK 04 - Python (DuckDB) Modern Stack")
print("─" * 60)

# ───────────────────────────────────────────────────────────────────────────────
## 2. I/O BENCHMARK (Data Load + Dual Indexing) ----
# ───────────────────────────────────────────────────────────────────────────────
#
# This phase measures the cost of:
#   1. Loading Parquet files into DuckDB tables
#   2. Converting WKB geometries to DuckDB spatial types
#   3. Building RTREE spatial indexes on BOTH datasets
#
# Indexing Strategy:
#   - Index on POINTS (p): Enables fast lookup "which points are in this polygon?"
#   - Index on POLYGONS (c): Enables fast lookup "which polygon contains this point?"
#   - Dual indexing optimizes bidirectional spatial queries
#
# Note: Indexing is included in I/O timing because it's a one-time setup cost
#       that enables all subsequent spatial queries to run faster.
# ───────────────────────────────────────────────────────────────────────────────

# Start memory and time tracking
tracemalloc.start()
start_time = time.perf_counter()

# Run the load operation ITERATIONS times
for _ in range(ITERATIONS):
    # Initialize in-memory DuckDB connection
    con = duckdb.connect()

    # Install and load the spatial extension (adds ST_* functions)
    con.install_extension("spatial")
    con.load_extension("spatial")

    # ── A. Load Address Points ──
    # Read Parquet file and convert WKB binary geometry to native DuckDB geometry
    # EXCLUDE(geometry) removes the WKB column after conversion
    con.execute(
        f"CREATE TABLE p AS "
        f"SELECT * EXCLUDE(geometry), ST_GeomFromWKB(geometry) AS geom "
        f"FROM '{ADDR_PQ}'"
    )

    # ── B. Load County Polygons ──
    # Same pattern: ingest Parquet and convert WKB to geometry
    con.execute(
        f"CREATE TABLE c AS "
        f"SELECT * EXCLUDE(geometry), ST_GeomFromWKB(geometry) AS geom "
        f"FROM '{COUNTY_PQ}'"
    )

    # ── C. Build Spatial Indexes (DUAL INDEXING) ──
    # RTREE is a hierarchical spatial index that enables fast spatial lookups
    # by organizing geometries into nested bounding boxes

    # Index the POINTS table (1.2M records)
    # This is critical for performance when polygons are queried against points
    con.execute("CREATE INDEX idx_p_geom ON p USING RTREE (geom);")

    # Index the POLYGONS table (29 records)
    # This helps when points are queried against polygons
    con.execute("CREATE INDEX idx_c_geom ON c USING RTREE (geom);")

# Note: You can verify index usage with:
# con.execute("EXPLAIN SELECT ... FROM p JOIN c ON ST_Within(...)").fetchall()
# Look for "RTREE_INDEX_SCAN" in the query plan

# Stop timing and memory tracking
end_time = time.perf_counter()
current_mem, peak_mem = tracemalloc.get_traced_memory()
tracemalloc.stop()

# Log the I/O + Indexing benchmark result
log_result("duckdb", "Python", "Load Data",
           end_time - start_time,
           peak_mem / 1024 / 1024)

# ───────────────────────────────────────────────────────────────────────────────
## 3. WARMUP QUERY (Populate Query Cache) ----
# ───────────────────────────────────────────────────────────────────────────────
#
# Why warmup?
#   - First query may trigger lazy evaluation or cache misses
#   - Warmup ensures subsequent timing reflects stable performance
#   - This is standard practice in database benchmarking
#
# Note: We use the existing connection (tables and indexes already built)
# ───────────────────────────────────────────────────────────────────────────────

print("Running warmup query (not timed)...")

# Define the spatial join query (same as the timed benchmark)
warmup_query = """
    SELECT c.FIPS_STR, COUNT(a.OBJECTID) AS point_count
    FROM p a
    INNER JOIN c ON ST_Within(a.geom, c.geom)
    GROUP BY c.FIPS_STR
"""

# Execute warmup query (result discarded, only for cache population)
_ = con.execute(warmup_query).fetchdf()

print("Warmup complete. Starting timed benchmark...")

# ───────────────────────────────────────────────────────────────────────────────
## 4. ANALYSIS BENCHMARK (Spatial Join) ----
# ───────────────────────────────────────────────────────────────────────────────
#
# This phase measures ONLY the spatial join query execution time.
#
# Query Logic:
#   - Join address points (p) with county polygons (c)
#   - Predicate: ST_Within(point, polygon) — "is this point inside this polygon?"
#   - Aggregate: COUNT points per county
#
# Performance Factors:
#   - Dual RTREE indexes guide the spatial search
#   - Explicit INNER JOIN syntax allows optimizer to choose best plan
#   - DuckDB's vectorized execution processes data in batches
#   - Columnar Parquet format means only needed columns are read
#
# Expected Result:
#   - With dual indexing: Fast execution (2-10 seconds)
#   - Without indexing: Slow execution (60+ seconds, full cross product scan)
# ───────────────────────────────────────────────────────────────────────────────

# Start memory and time tracking for the analysis phase
tracemalloc.start()
start_time = time.perf_counter()

# Run the analysis operation ITERATIONS times
for _ in range(ITERATIONS):
    # Define the spatial join query
    # Using explicit INNER JOIN (not comma join) for better optimization
    query = """
        SELECT c.FIPS_STR, COUNT(a.OBJECTID) AS point_count
        FROM p a
        INNER JOIN c ON ST_Within(a.geom, c.geom)
        GROUP BY c.FIPS_STR
    """

    # Execute query and retrieve results as pandas DataFrame
    result = con.execute(query).fetchdf()

# Stop timing and memory tracking
end_time = time.perf_counter()
current_mem, peak_mem = tracemalloc.get_traced_memory()
tracemalloc.stop()

# Log the spatial join benchmark result
log_result("duckdb", "Python", "Validation (Join)",
           end_time - start_time,
           peak_mem / 1024 / 1024)

# ───────────────────────────────────────────────────────────────────────────────
## 5. CLEANUP ----
# ───────────────────────────────────────────────────────────────────────────────

# Close database connection (releases resources)
con.close()

print("─" * 60)
print("BENCHMARK 04 Complete!")
print("─" * 60)

# ═══════════════════════════════════════════════════════════════════════════════
# END OF BENCHMARK 04
# ═══════════════════════════════════════════════════════════════════════════════
