import time
import tracemalloc
import duckdb

RESULTS_CSV = "_results/benchmark_results.csv"

def log_result(sys, lang, op, time_sec, peak_mem_mb):
    with open(RESULTS_CSV, "a") as f:
        f.write(f"{sys},{lang},{op},{time_sec:.4f},{peak_mem_mb:.2f}\n")

ADDR_PQ = "_data/utah_addresses.parquet"
COUNTY_PQ = "_data/utah_counties.parquet"

print("--- 04: Python (DuckDB) Modern (Indexed) ---")

# 1. I/O Benchmark
tracemalloc.start()
start = time.perf_counter()

con = duckdb.connect()
con.install_extension("spatial"); con.load_extension("spatial")

# A. Ingest Addresses (Convert WKB -> Geometry)
con.execute(f"CREATE TABLE p AS SELECT * EXCLUDE(geometry), ST_GeomFromWKB(geometry) AS geom FROM '{ADDR_PQ}'")

# B. Ingest Counties (Convert WKB -> Geometry)
con.execute(f"CREATE TABLE c AS SELECT * EXCLUDE(geometry), ST_GeomFromWKB(geometry) AS geom FROM '{COUNTY_PQ}'")

# C. Build Index
con.execute("CREATE INDEX idx_c_geom ON c USING RTREE (geom)")

end = time.perf_counter()
current, peak = tracemalloc.get_traced_memory()
tracemalloc.stop()
log_result("duckdb", "Python", "Load Data", end - start, peak / 1024 / 1024)

# 2. Analysis Benchmark
tracemalloc.start()
start = time.perf_counter()

query = """
    SELECT c.FIPS_STR, COUNT(a.OBJECTID)
    FROM p a, c
    WHERE ST_Within(a.geom, c.geom)
    GROUP BY c.FIPS_STR
"""
con.execute(query).fetchdf()

end = time.perf_counter()
current, peak = tracemalloc.get_traced_memory()
tracemalloc.stop()
log_result("duckdb", "Python", "Validation (Join)", end - start, peak / 1024 / 1024)
