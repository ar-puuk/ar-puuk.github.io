# ═══════════════════════════════════════════════════════════════════════════════
# BENCHMARK 02: Modern R Stack (DuckDB + Parquet + Spatial Index)
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
#   - Portable SQL logic (same query works in Python)
#
# Author: Pukar Bhandari
# Date: 2026-02-08
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────────
## 1. SETUP & CONFIGURATION ----
# ───────────────────────────────────────────────────────────────────────────────

library(duckdb) # Embedded OLAP database with spatial extension
library(dplyr) # Data manipulation (used for validation output)
library(bench) # High-precision benchmarking with memory tracking
library(DBI) # Database interface for DuckDB
library(readr) # Fast CSV writing for validation results

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

# Define input file paths (Parquet format with WKB-encoded geometries)
addr_pq <- "_data/utah_addresses.parquet" # ~1.2M address points
county_pq <- "_data/utah_counties.parquet" # 29 county polygons

message("────────────────────────────────────────────────────────────")
message("Running: BENCHMARK 02 - R (DuckDB) Modern Stack")
message("────────────────────────────────────────────────────────────")

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

bm_io <- bench::mark(
  load_data = {
    # Initialize in-memory DuckDB connection
    con <- dbConnect(duckdb())

    # Install and load the spatial extension (adds ST_* functions)
    dbExecute(con, "INSTALL spatial;")
    dbExecute(con, "LOAD spatial;")

    # ── A. Load Address Points ──
    # Read Parquet file and convert WKB binary geometry to native DuckDB geometry
    # EXCLUDE(geometry) removes the WKB column after conversion
    dbExecute(
      con,
      sprintf(
        "CREATE TABLE p AS
         SELECT * EXCLUDE(geometry),
                ST_GeomFromWKB(geometry) AS geom
         FROM '%s'",
        addr_pq
      )
    )

    # ── B. Load County Polygons ──
    # Same pattern: ingest Parquet and convert WKB to geometry
    dbExecute(
      con,
      sprintf(
        "CREATE TABLE c AS
         SELECT * EXCLUDE(geometry),
                ST_GeomFromWKB(geometry) AS geom
         FROM '%s'",
        county_pq
      )
    )

    # ── C. Build Spatial Indexes (DUAL INDEXING) ──
    # RTREE is a hierarchical spatial index that enables fast spatial lookups
    # by organizing geometries into nested bounding boxes

    # Index the POINTS table (1.2M records)
    # This is critical for performance when polygons are queried against points
    dbExecute(con, "CREATE INDEX idx_p_geom ON p USING RTREE (geom);")

    # Index the POLYGONS table (29 records)
    # This helps when points are queried against polygons
    dbExecute(con, "CREATE INDEX idx_c_geom ON c USING RTREE (geom);")

    # Note: You can verify index usage with:
    # dbGetQuery(con, "EXPLAIN SELECT ... FROM p JOIN c ON ST_Within(...)")
    # Look for "RTREE_INDEX_SCAN" in the query plan
  },
  iterations = ITERATIONS, # Controlled by index.qmd or run_all.R
  check = FALSE # Skip bench::mark's equality checking
)

# Log the I/O + Indexing benchmark result
log_result("duckdb", "R", "Load Data", bm_io)

# ───────────────────────────────────────────────────────────────────────────────
## 3. WARMUP QUERY (Populate Query Cache) ----
# ───────────────────────────────────────────────────────────────────────────────
#
# Re-establish connection and rebuild tables for the analysis phase.
# This ensures we're measuring ONLY the query execution time, not setup time.
#
# Why warmup?
#   - First query may trigger lazy evaluation or cache misses
#   - Warmup ensures subsequent timing reflects stable performance
#   - This is standard practice in database benchmarking
# ───────────────────────────────────────────────────────────────────────────────

message("Running warmup query (not timed)...")

# Re-create the DuckDB environment (fresh connection)
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL spatial;")
dbExecute(con, "LOAD spatial;")

# Rebuild tables with spatial indexes
dbExecute(
  con,
  sprintf(
    "CREATE TABLE p AS
     SELECT * EXCLUDE(geometry),
            ST_GeomFromWKB(geometry) AS geom
     FROM '%s'",
    addr_pq
  )
)

dbExecute(
  con,
  sprintf(
    "CREATE TABLE c AS
     SELECT * EXCLUDE(geometry),
            ST_GeomFromWKB(geometry) AS geom
     FROM '%s'",
    county_pq
  )
)

# Rebuild spatial indexes
dbExecute(con, "CREATE INDEX idx_p_geom ON p USING RTREE (geom);")
dbExecute(con, "CREATE INDEX idx_c_geom ON c USING RTREE (geom);")

# Execute the spatial join query once (result discarded, only for cache warmup)
warmup_sql <- "
  SELECT c.FIPS_STR, COUNT(a.OBJECTID) AS point_count
  FROM p a
  INNER JOIN c ON ST_Within(a.geom, c.geom)
  GROUP BY c.FIPS_STR
"
invisible(dbGetQuery(con, warmup_sql))

message("Warmup complete. Starting timed benchmark...")

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

bm_analysis <- bench::mark(
  validation = {
    # Define the spatial join query
    # Using explicit INNER JOIN (not comma join) for better optimization
    sql <- "
      SELECT c.FIPS_STR, COUNT(a.OBJECTID) AS point_count
      FROM p a
      INNER JOIN c ON ST_Within(a.geom, c.geom)
      GROUP BY c.FIPS_STR
    "

    # Execute query and retrieve results
    res <- dbGetQuery(con, sql)
  },
  iterations = ITERATIONS, # Controlled by index.qmd or run_all.R
  check = FALSE # Disable bench::mark's comparison checks
)

# Log the spatial join benchmark result
log_result("duckdb", "R", "Validation (Join)", bm_analysis)

# ───────────────────────────────────────────────────────────────────────────────
## 5. VALIDATION & EXPORT ----
# ───────────────────────────────────────────────────────────────────────────────
#
# Compare attribute-based counts vs spatial join counts to identify mismatches.
# This validates data quality: does the CountyID field match the actual location?
#
# Output: Top 10 counties with the largest discrepancies
# ───────────────────────────────────────────────────────────────────────────────

message("Generating validation statistics...")

sql_diff <- "
WITH attr_counts AS (
    -- Count addresses by their labeled CountyID attribute
    SELECT CountyID, COUNT(*) AS count_attr
    FROM p
    GROUP BY CountyID
),
spatial_counts AS (
    -- Count addresses by actual spatial location (point-in-polygon)
    SELECT c.FIPS_STR, COUNT(a.OBJECTID) AS count_spatial
    FROM p a
    INNER JOIN c ON ST_Within(a.geom, c.geom)
    GROUP BY c.FIPS_STR
)
SELECT
    COALESCE(a.CountyID, s.FIPS_STR) AS CountyID,
    COALESCE(a.count_attr, 0) AS count_attr,
    COALESCE(s.count_spatial, 0) AS count_spatial,
    (COALESCE(a.count_attr, 0) - COALESCE(s.count_spatial, 0)) AS diff
FROM attr_counts a
FULL OUTER JOIN spatial_counts s ON a.CountyID = s.FIPS_STR
ORDER BY ABS(diff) DESC
LIMIT 10;
"

# Execute validation query and export to CSV
stats <- dbGetQuery(con, sql_diff)
write_csv(stats, "_results/validation_stats.csv")

message("Validation stats saved to: _results/validation_stats.csv")

# ───────────────────────────────────────────────────────────────────────────────
## 6. CLEANUP ----
# ───────────────────────────────────────────────────────────────────────────────

# Close database connection (releases resources)
dbDisconnect(con)

message("────────────────────────────────────────────────────────────")
message("BENCHMARK 02 Complete!")
message("────────────────────────────────────────────────────────────")

# ═══════════════════════════════════════════════════════════════════════════════
# END OF BENCHMARK 02
# ═══════════════════════════════════════════════════════════════════════════════
