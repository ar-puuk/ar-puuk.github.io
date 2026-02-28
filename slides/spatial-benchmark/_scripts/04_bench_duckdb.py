# ═══════════════════════════════════════════════════════════════════════════════
# BENCHMARK 04: Modern Python Stack (DuckDB + Parquet + Spatial Index)
# ═══════════════════════════════════════════════════════════════════════════════
# Purpose: Demonstrate DuckDB's efficiency for large-scale spatial operations
#          using columnar storage (Parquet) and RTREE spatial indexing.
#
# FIX NOTES (vs. original):
#
#   FIX 1 — ST_Intersects instead of ST_Within in JOIN:
#     DuckDB's RTREE index only accelerates bounding-box queries. ST_Within in
#     a JOIN condition causes a BLOCKWISE_NL_JOIN (no index). ST_Intersects IS
#     RTREE-accelerated for point-polygon (a point can't straddle a boundary,
#     so ST_Intersects == ST_Within for points). Verify with EXPLAIN.
#
#   FIX 2 — Table order: FROM c INNER JOIN p (polygons as left/build side):
#     Lets DuckDB iterate 29 polygons and use the RTREE on 1.2M points to
#     retrieve candidates per polygon. Opposite order forces full point scan.
#
#   FIX 3 — install_extension called once in setup, not in benchmark loop:
#     install_extension() performs a network version-check even when cached.
#     This inflates DuckDB's "Load Data" time with overhead unrelated to I/O.
#     The spatial extension is installed once in 00_setup_data.R (R side) or
#     in a one-time setup block here.
#
#   FIX 4 — Honest memory measurement via psutil RSS:
#     tracemalloc only tracks Python-managed objects. DuckDB's C++ engine
#     allocates in its own arena, invisible to tracemalloc. psutil.Process()
#     .memory_info().rss captures the actual process resident set size.
#
#   FIX 5 — Split Load phase into Ingest + Build Index:
#     Separates the one-time indexing cost from pure I/O for a fair
#     comparison with geopandas/sf (which have no explicit index step).
#
# Author: Pukar Bhandari
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────────
## 1. SETUP & CONFIGURATION ----
# ───────────────────────────────────────────────────────────────────────────────

import os
import sys
import time
import statistics
import duckdb
import psutil       # FIX 4: for honest RSS-based memory measurement
from pathlib import Path

ITERATIONS = int(os.environ.get('BENCHMARK_ITERATIONS', '1'))

RESULTS_CSV = "_results/benchmark_results.csv"
ADDR_PQ    = "_data/utah_addresses.parquet"
COUNTY_PQ  = "_data/utah_counties.parquet"

def log_result(sys_name, lang, op, time_sec, peak_mem_mb):
    with open(RESULTS_CSV, "a") as f:
        f.write(f"{sys_name},{lang},{op},{time_sec:.4f},{peak_mem_mb:.2f}\n")

# FIX 4: RSS-based memory measurement
proc = psutil.Process(os.getpid())

def rss_mb():
    return proc.memory_info().rss / 1024 / 1024

print("─" * 60)
print("Running: BENCHMARK 04 - Python (DuckDB) Modern Stack")
print("─" * 60)

# ───────────────────────────────────────────────────────────────────────────────
## 2. ONE-TIME SETUP — Install Spatial Extension (not timed) ----
# ───────────────────────────────────────────────────────────────────────────────
#
# FIX 3: Install the spatial extension ONCE outside the benchmark loop.
# Subsequent benchmark iterations use LOAD spatial (fast, no network check).
# ───────────────────────────────────────────────────────────────────────────────

print("Installing spatial extension (one-time, not timed)...")
_setup_con = duckdb.connect()
_setup_con.install_extension("spatial")
_setup_con.close()
print("Spatial extension ready.")

# ───────────────────────────────────────────────────────────────────────────────
## 3. I/O BENCHMARK A — Ingest (Data Load Only, No Indexing) ----
# ───────────────────────────────────────────────────────────────────────────────
#
# FIX 3: Only LOAD spatial (fast), no install. Measures only Parquet ingest.
# FIX 4: RSS delta instead of tracemalloc.
# FIX 5: Index creation is a separate timed phase.
# ───────────────────────────────────────────────────────────────────────────────

ingest_times = []
ingest_mems  = []

for _ in range(ITERATIONS):
    mem_before = rss_mb()
    t_start    = time.perf_counter()

    con_i = duckdb.connect()
    con_i.load_extension("spatial")   # FIX 3: LOAD only

    con_i.execute(
        f"CREATE TABLE p AS "
        f"SELECT * EXCLUDE(geometry), ST_GeomFromWKB(geometry) AS geom "
        f"FROM '{ADDR_PQ}'"
    )
    con_i.execute(
        f"CREATE TABLE c AS "
        f"SELECT * EXCLUDE(geometry), ST_GeomFromWKB(geometry) AS geom "
        f"FROM '{COUNTY_PQ}'"
    )
    con_i.close()

    ingest_times.append(time.perf_counter() - t_start)
    ingest_mems.append(rss_mb() - mem_before)

log_result("duckdb", "Python", "Load Data",
           statistics.median(ingest_times),
           max(ingest_mems))
print(f"  Load Data: {statistics.median(ingest_times):.3f}s | {max(ingest_mems):.1f} MB RSS delta")

# ───────────────────────────────────────────────────────────────────────────────
## 4. I/O BENCHMARK B — Build Index ----
# ───────────────────────────────────────────────────────────────────────────────
#
# FIX 5: Index creation measured separately as a standalone operation.
# ───────────────────────────────────────────────────────────────────────────────

# Persistent connection for analysis phase
con = duckdb.connect()
con.load_extension("spatial")
con.execute(
    f"CREATE TABLE p AS "
    f"SELECT * EXCLUDE(geometry), ST_GeomFromWKB(geometry) AS geom "
    f"FROM '{ADDR_PQ}'"
)
con.execute(
    f"CREATE TABLE c AS "
    f"SELECT * EXCLUDE(geometry), ST_GeomFromWKB(geometry) AS geom "
    f"FROM '{COUNTY_PQ}'"
)

index_times = []
index_mems  = []

for _ in range(ITERATIONS):
    # Drop and rebuild so each iteration is independent
    try:
        con.execute("DROP INDEX IF EXISTS idx_p_geom;")
        con.execute("DROP INDEX IF EXISTS idx_c_geom;")
    except Exception:
        pass

    mem_before = rss_mb()
    t_start    = time.perf_counter()

    con.execute("CREATE INDEX idx_p_geom ON p USING RTREE (geom);")
    con.execute("CREATE INDEX idx_c_geom ON c USING RTREE (geom);")

    index_times.append(time.perf_counter() - t_start)
    index_mems.append(rss_mb() - mem_before)

log_result("duckdb", "Python", "Build Index",
           statistics.median(index_times),
           max(index_mems))
print(f"  Build Index: {statistics.median(index_times):.3f}s | {max(index_mems):.1f} MB RSS delta")

# ───────────────────────────────────────────────────────────────────────────────
## 5. WARMUP QUERY ----
# ───────────────────────────────────────────────────────────────────────────────

print("Running warmup query (not timed)...")

# FIX 1 + FIX 2: ST_Intersects (RTREE-accelerated) + c as build side (29 rows)
warmup_query = """
    SELECT c.FIPS_STR, COUNT(a.OBJECTID) AS point_count
    FROM c
    INNER JOIN p a ON ST_Intersects(a.geom, c.geom)
    GROUP BY c.FIPS_STR
"""
_ = con.execute(warmup_query).fetchdf()
print("Warmup complete. Starting timed benchmark...")

# ───────────────────────────────────────────────────────────────────────────────
## 6. ANALYSIS BENCHMARK (Spatial Join) ----
# ───────────────────────────────────────────────────────────────────────────────
#
# FIX 1: ST_Intersects instead of ST_Within.
#   For point geometries, these produce identical results. But ST_Intersects
#   is RTREE-accelerated while ST_Within falls back to nested-loop scan.
#   Check the query plan with:
#       print(con.execute("EXPLAIN " + query).fetchall())
#   Look for RTREE_INDEX_SCAN (good) vs BLOCKWISE_NL_JOIN (slow).
#
# FIX 2: FROM c INNER JOIN p a — polygon-first join order.
#   With 29 polygons on the left (build) side, DuckDB iterates each polygon
#   and uses the RTREE index on p (1.2M points) to retrieve candidate points
#   within each polygon's bounding box, then does exact intersection check.
# ───────────────────────────────────────────────────────────────────────────────

query = """
    SELECT c.FIPS_STR, COUNT(a.OBJECTID) AS point_count
    FROM c
    INNER JOIN p a ON ST_Intersects(a.geom, c.geom)
    GROUP BY c.FIPS_STR
"""

join_times = []
join_mems  = []

for _ in range(ITERATIONS):
    mem_before = rss_mb()
    t_start    = time.perf_counter()

    result = con.execute(query).fetchdf()

    join_times.append(time.perf_counter() - t_start)
    join_mems.append(rss_mb() - mem_before)

log_result("duckdb", "Python", "Validation (Join)",
           statistics.median(join_times),
           max(join_mems))
print(f"  Validation (Join): {statistics.median(join_times):.3f}s | {max(join_mems):.1f} MB RSS delta")

# ───────────────────────────────────────────────────────────────────────────────
## 7. CLEANUP ----
# ───────────────────────────────────────────────────────────────────────────────

con.close()

print("─" * 60)
print("BENCHMARK 04 Complete!")
print("─" * 60)
