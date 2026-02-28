# ═══════════════════════════════════════════════════════════════════════════════
# BENCHMARK 06: Modern Python Stack (Apache SedonaDB + Parquet)
# ═══════════════════════════════════════════════════════════════════════════════
# Architecture notes:
#   - SedonaDB Python is the same embedded Rust/DataFusion engine as the R
#     package — same query planner, same performance characteristics.
#   - Install: pip install "apache-sedona[db]"
#   - API: sedona.db.connect() returns a connection with a .sql() method
#     that returns a DataFrame-like result.
#   - Lazy evaluation: read_parquet() + create_view() registers a view
#     definition — no data scanned until .collect() fires.
#
# Case sensitivity note (same as R version):
#   DataFusion is CASE-SENSITIVE. Column names must be double-quoted in SQL
#   to preserve original case from the Parquet schema.
#
# Author: Pukar Bhandari
# ═══════════════════════════════════════════════════════════════════════════════

import os
import time
import statistics
import psutil
import sedona.db

ITERATIONS = int(os.environ.get("BENCHMARK_ITERATIONS", "1"))

RESULTS_CSV = "_results/benchmark_results.csv"
ADDR_PQ     = "_data/utah_addresses.parquet"
COUNTY_PQ   = "_data/utah_counties.parquet"

def log_result(sys_name, lang, op, time_sec, peak_mem_mb):
    with open(RESULTS_CSV, "a") as f:
        f.write(f"{sys_name},{lang},{op},{time_sec:.4f},{peak_mem_mb:.2f}\n")

proc = psutil.Process(os.getpid())

def rss_mb():
    return proc.memory_info().rss / 1024 / 1024

print("─" * 60)
print("Running: BENCHMARK 06 - Python (SedonaDB) Modern Stack")
print("─" * 60)

# ───────────────────────────────────────────────────────────────────────────────
## 2. CONNECT ----
# ───────────────────────────────────────────────────────────────────────────────
# Single persistent connection — SedonaDB manages its own session state.
# ───────────────────────────────────────────────────────────────────────────────

sd = sedona.db.connect()

# ───────────────────────────────────────────────────────────────────────────────
## 3. I/O BENCHMARK — Load Data ----
# ───────────────────────────────────────────────────────────────────────────────
#
# read_parquet() + create_view() is LAZY — no data scanned until .collect().
# "Load Data" timing measures view registration only (~0.01s).
# Actual Parquet scan happens during "Validation (Join)" when .collect() fires.
#
# Column schemas confirmed from live Parquet files (same as R version):
#
#   Address (UGRC UtahAddressPoints):
#     OBJECTID, AddSystem, UTAddPtID, FullAdd, AddNum, AddNumSuffix, PrefixDir,
#     StreetName, StreetType, SuffixDir, LandmarkName, Building, UnitType,
#     UnitID, City, ZipCode, CountyID, State, PtLocation, PtType, Structure,
#     ParcelID, AddSource, LoadDate, USNG, geometry
#
#   Counties (UGRC UtahCountyBoundaries):
#     OBJECTID, COUNTYNBR, ENTITYNBR, ENTITYYR, NAME, FIPS, STATEPLANE,
#     POP_LASTCENSUS, POP_CURRESTIMATE, GlobalID, FIPS_STR, COLOR4,
#     Shape__Area, Shape__Length, CLASS, geometry
# ───────────────────────────────────────────────────────────────────────────────

load_times = []
load_mems  = []

for _ in range(ITERATIONS):
    mem_before = rss_mb()
    t_start    = time.perf_counter()

    # Register raw Parquet views (lazy — no I/O yet)
    sd.read_parquet(ADDR_PQ).create_view("addr_raw",   replace=True)
    sd.read_parquet(COUNTY_PQ).create_view("county_raw", replace=True)

    # Geometry-converted views — all identifiers double-quoted (case-sensitive)
    sd.sql("""
        SELECT
          "OBJECTID", "AddSystem", "UTAddPtID", "FullAdd", "AddNum",
          "AddNumSuffix", "PrefixDir", "StreetName", "StreetType", "SuffixDir",
          "LandmarkName", "Building", "UnitType", "UnitID", "City", "ZipCode",
          "CountyID", "State", "PtLocation", "PtType", "Structure", "ParcelID",
          "AddSource", "LoadDate", "USNG",
          ST_GeomFromWKB(geometry) AS geom
        FROM addr_raw
    """).create_view("p", replace=True)

    sd.sql("""
        SELECT
          "OBJECTID", "COUNTYNBR", "ENTITYNBR", "ENTITYYR", "NAME", "FIPS",
          "STATEPLANE", "POP_LASTCENSUS", "POP_CURRESTIMATE", "GlobalID",
          "FIPS_STR", "COLOR4", "Shape__Area", "Shape__Length", "CLASS",
          ST_GeomFromWKB(geometry) AS geom
        FROM county_raw
    """).create_view("c", replace=True)

    load_times.append(time.perf_counter() - t_start)
    load_mems.append(rss_mb() - mem_before)

log_result("sedonadb", "Python", "Load Data",
           statistics.median(load_times), max(load_mems))
print(f"  Load Data: {statistics.median(load_times):.3f}s | {max(load_mems):.1f} MB RSS delta")

# ───────────────────────────────────────────────────────────────────────────────
## 4. WARMUP QUERY ----
# ───────────────────────────────────────────────────────────────────────────────

print("Running warmup query (not timed)...")

sd.sql("""
    SELECT c."FIPS_STR", COUNT(*) AS point_count
    FROM c
    INNER JOIN p a ON ST_Intersects(a.geom, c.geom)
    GROUP BY c."FIPS_STR"
""").collect()

print("Warmup complete. Starting timed benchmark...")

# ───────────────────────────────────────────────────────────────────────────────
## 5. ANALYSIS BENCHMARK — Spatial Join ----
# ───────────────────────────────────────────────────────────────────────────────
#
# Because views are lazy, .collect() here triggers the ACTUAL Parquet scan
# in addition to the join. "Validation (Join)" includes full I/O + compute.
# ───────────────────────────────────────────────────────────────────────────────

query = """
    SELECT c."FIPS_STR", COUNT(*) AS point_count
    FROM c
    INNER JOIN p a ON ST_Intersects(a.geom, c.geom)
    GROUP BY c."FIPS_STR"
"""

join_times = []
join_mems  = []

for _ in range(ITERATIONS):
    mem_before = rss_mb()
    t_start    = time.perf_counter()

    result = sd.sql(query).collect()

    join_times.append(time.perf_counter() - t_start)
    join_mems.append(rss_mb() - mem_before)

log_result("sedonadb", "Python", "Validation (Join)",
           statistics.median(join_times), max(join_mems))
print(f"  Validation (Join): {statistics.median(join_times):.3f}s | {max(join_mems):.1f} MB RSS delta")

# ───────────────────────────────────────────────────────────────────────────────
## 6. CLEANUP ----
# ───────────────────────────────────────────────────────────────────────────────

sd.sql("DROP VIEW IF EXISTS p")
sd.sql("DROP VIEW IF EXISTS c")
sd.sql("DROP VIEW IF EXISTS addr_raw")
sd.sql("DROP VIEW IF EXISTS county_raw")

print("─" * 60)
print("BENCHMARK 06 Complete!")
print("─" * 60)
