# ═══════════════════════════════════════════════════════════════════════════════
# BENCHMARK 02: Modern R Stack (DuckDB + Parquet + Spatial Index)
# ═══════════════════════════════════════════════════════════════════════════════
# FIX (vs previous version):
#
#   force(expr) promise-caching bug (same as 01_bench_sf.R):
#     measure_rss() now accepts a function and calls fn() each iteration
#     so the body re-executes every time. Call sites use function() { ... }.
#
#   Removed unused library(bench):
#     bench::mark() was replaced by measure_rss() but the import was left in.
#
# Previous fixes retained:
#   - ST_Intersects + polygon-first join order (RTREE acceleration)
#   - LOAD spatial only (INSTALL spatial is in 00_setup_data.R)
#   - RSS-based memory measurement
#   - Split Load Data and Build Index into separate timed phases
#
# Author: Pukar Bhandari
# ═══════════════════════════════════════════════════════════════════════════════

library(duckdb)
library(dplyr)
library(DBI)
library(readr)
library(ps)

results_csv <- "_results/benchmark_results.csv"

ITERATIONS <- as.integer(
  Sys.getenv(
    "BENCHMARK_ITERATIONS",
    unset = ifelse(exists("ITERATIONS"), as.character(ITERATIONS), "1")
  )
)

# Helper: accepts a FUNCTION, calls fn() on each iteration (no promise caching).
measure_rss <- function(fn, iterations = 1L) {
  times <- numeric(iterations)
  mem_deltas <- numeric(iterations)

  for (i in seq_len(iterations)) {
    gc(verbose = FALSE)
    mem_before <- ps::ps_memory_info()[["rss"]]
    t_start <- proc.time()[["elapsed"]]

    fn()

    t_end <- proc.time()[["elapsed"]]
    times[i] <- t_end - t_start
    mem_deltas[i] <- (ps::ps_memory_info()[["rss"]] - mem_before) / 1024 / 1024
  }

  list(time_sec = median(times), mem_mb = max(mem_deltas))
}

log_result <- function(sys, lang, op, time_sec, mem_mb) {
  cat(
    sprintf("%s,%s,%s,%.4f,%.2f\n", sys, lang, op, time_sec, mem_mb),
    file = results_csv,
    append = TRUE
  )
}

addr_pq <- "_data/utah_addresses.parquet"
county_pq <- "_data/utah_counties.parquet"

message("────────────────────────────────────────────────────────────")
message("Running: BENCHMARK 02 - R (DuckDB) Modern Stack")
message("────────────────────────────────────────────────────────────")

# ───────────────────────────────────────────────────────────────────────────────
## 2. I/O BENCHMARK A — Ingest (Data Load Only, No Indexing) ----
# ───────────────────────────────────────────────────────────────────────────────
#
# Measures: connect + LOAD spatial + CREATE TABLE from Parquet (WKB conversion).
# No RTREE index creation — that is a separate phase below.
# Fair comparison with sf/GeoPandas Load Data (pure I/O, no indexing).
# ───────────────────────────────────────────────────────────────────────────────

message("Phase 2a: Benchmarking data ingest (no indexing)...")

res_ingest <- measure_rss(
  function() {
    con_i <- dbConnect(duckdb())
    dbExecute(con_i, "LOAD spatial;")

    dbExecute(
      con_i,
      sprintf(
        "CREATE TABLE p AS
     SELECT * EXCLUDE(geometry), ST_GeomFromWKB(geometry) AS geom
     FROM '%s'",
        addr_pq
      )
    )
    dbExecute(
      con_i,
      sprintf(
        "CREATE TABLE c AS
     SELECT * EXCLUDE(geometry), ST_GeomFromWKB(geometry) AS geom
     FROM '%s'",
        county_pq
      )
    )
    dbDisconnect(con_i)
  },
  iterations = ITERATIONS
)

log_result("duckdb", "R", "Load Data", res_ingest$time_sec, res_ingest$mem_mb)
message(sprintf(
  "  Load Data: %.3fs | %.1f MB RSS delta",
  res_ingest$time_sec,
  res_ingest$mem_mb
))

# ───────────────────────────────────────────────────────────────────────────────
## 3. I/O BENCHMARK B — Build Index ----
# ───────────────────────────────────────────────────────────────────────────────
#
# Separated from Load Data to show the one-time RTREE index creation cost
# explicitly. This cost is amortized across all subsequent queries.
# ───────────────────────────────────────────────────────────────────────────────

message("Phase 2b: Benchmarking RTREE index creation...")

# Persistent connection for analysis phase — tables stay in memory
con <- dbConnect(duckdb())
dbExecute(con, "LOAD spatial;")
dbExecute(
  con,
  sprintf(
    "CREATE TABLE p AS
   SELECT * EXCLUDE(geometry), ST_GeomFromWKB(geometry) AS geom
   FROM '%s'",
    addr_pq
  )
)
dbExecute(
  con,
  sprintf(
    "CREATE TABLE c AS
   SELECT * EXCLUDE(geometry), ST_GeomFromWKB(geometry) AS geom
   FROM '%s'",
    county_pq
  )
)

res_index <- measure_rss(
  function() {
    # Drop and rebuild so each iteration is independently timed
    tryCatch(
      dbExecute(con, "DROP INDEX IF EXISTS idx_p_geom;"),
      error = function(e) NULL
    )
    tryCatch(
      dbExecute(con, "DROP INDEX IF EXISTS idx_c_geom;"),
      error = function(e) NULL
    )
    dbExecute(con, "CREATE INDEX idx_p_geom ON p USING RTREE (geom);")
    dbExecute(con, "CREATE INDEX idx_c_geom ON c USING RTREE (geom);")
  },
  iterations = ITERATIONS
)

log_result("duckdb", "R", "Build Index", res_index$time_sec, res_index$mem_mb)
message(sprintf(
  "  Build Index: %.3fs | %.1f MB RSS delta",
  res_index$time_sec,
  res_index$mem_mb
))

# ───────────────────────────────────────────────────────────────────────────────
## 4. WARMUP QUERY ----
# ───────────────────────────────────────────────────────────────────────────────

message("Running warmup query (not timed)...")

warmup_sql <- "
  SELECT c.FIPS_STR, COUNT(a.OBJECTID) AS point_count
  FROM c
  INNER JOIN p a ON ST_Intersects(a.geom, c.geom)
  GROUP BY c.FIPS_STR
"
invisible(dbGetQuery(con, warmup_sql))
message("Warmup complete. Starting timed benchmark...")

# ───────────────────────────────────────────────────────────────────────────────
## 5. ANALYSIS BENCHMARK (Spatial Join) ----
# ───────────────────────────────────────────────────────────────────────────────
#
# ST_Intersects (not ST_Within) — DuckDB's RTREE accelerates ST_Intersects.
# ST_Within in a JOIN falls back to BLOCKWISE_NL_JOIN (no index).
# For point geometries, ST_Intersects == ST_Within (points can't straddle a boundary).
#
# FROM c INNER JOIN p — polygon-first order (29 rows) lets DuckDB iterate
# polygons and use the RTREE on 1.2M points to retrieve candidates per polygon.
# ───────────────────────────────────────────────────────────────────────────────

sql <- "
  SELECT c.FIPS_STR, COUNT(a.OBJECTID) AS point_count
  FROM c
  INNER JOIN p a ON ST_Intersects(a.geom, c.geom)
  GROUP BY c.FIPS_STR
"

res_join <- measure_rss(
  function() {
    res <- dbGetQuery(con, sql)
  },
  iterations = ITERATIONS
)

log_result(
  "duckdb",
  "R",
  "Validation (Join)",
  res_join$time_sec,
  res_join$mem_mb
)
message(sprintf(
  "  Validation (Join): %.3fs | %.1f MB RSS delta",
  res_join$time_sec,
  res_join$mem_mb
))

# ───────────────────────────────────────────────────────────────────────────────
## 6. VALIDATION & EXPORT ----
# ───────────────────────────────────────────────────────────────────────────────

message("Generating validation statistics...")

sql_diff <- "
WITH attr_counts AS (
    SELECT CountyID, COUNT(*) AS count_attr
    FROM p
    GROUP BY CountyID
),
spatial_counts AS (
    SELECT c.FIPS_STR, COUNT(a.OBJECTID) AS count_spatial
    FROM c
    INNER JOIN p a ON ST_Intersects(a.geom, c.geom)
    GROUP BY c.FIPS_STR
)
SELECT
    COALESCE(a.CountyID, s.FIPS_STR)     AS CountyID,
    COALESCE(a.count_attr,    0)          AS count_attr,
    COALESCE(s.count_spatial, 0)          AS count_spatial,
    (COALESCE(a.count_attr, 0) - COALESCE(s.count_spatial, 0)) AS diff
FROM attr_counts a
FULL OUTER JOIN spatial_counts s ON a.CountyID = s.FIPS_STR
ORDER BY ABS(diff) DESC
LIMIT 10;
"

stats <- dbGetQuery(con, sql_diff)
write_csv(stats, "_results/validation_stats.csv")
message("Validation stats saved to: _results/validation_stats.csv")

# ───────────────────────────────────────────────────────────────────────────────
## 7. CLEANUP ----
# ───────────────────────────────────────────────────────────────────────────────

dbDisconnect(con)

message("────────────────────────────────────────────────────────────")
message("BENCHMARK 02 Complete!")
message("────────────────────────────────────────────────────────────")
