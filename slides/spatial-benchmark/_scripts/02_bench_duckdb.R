library(duckdb)
library(dplyr)
library(bench)
library(DBI)
library(readr)

# Output to _results folder
results_csv <- "_results/benchmark_results.csv"

log_result <- function(sys, lang, op, bm) {
  time_sec <- as.numeric(bm$median)
  mem_mb <- as.numeric(bm$mem_alloc) / 1024 / 1024
  cat(
    sprintf("%s,%s,%s,%.4f,%.2f\n", sys, lang, op, time_sec, mem_mb),
    file = results_csv,
    append = TRUE
  )
}

addr_pq <- "_data/utah_addresses.parquet"
county_pq <- "_data/utah_counties.parquet"

message("--- 02: R (DuckDB) Modern (Indexed) ---")

# 1. I/O Benchmark (Load + Parse + Index)
bm_io <- bench::mark(
  load_data = {
    con <- dbConnect(duckdb())
    dbExecute(con, "INSTALL spatial; LOAD spatial;")

    # A. Load Addresses
    dbExecute(
      con,
      sprintf(
        "CREATE TABLE p AS SELECT * EXCLUDE(geometry), ST_GeomFromWKB(geometry) AS geom FROM '%s'",
        addr_pq
      )
    )

    # B. Load Counties
    dbExecute(
      con,
      sprintf(
        "CREATE TABLE c AS SELECT * EXCLUDE(geometry), ST_GeomFromWKB(geometry) AS geom FROM '%s'",
        county_pq
      )
    )

    # C. Build Spatial Index (RTREE)
    dbExecute(con, "CREATE INDEX idx_c_geom ON c USING RTREE (geom)")
  },
  iterations = 1,
  check = FALSE
)
log_result("duckdb", "R", "Load Data", bm_io)

# Re-connect for Analysis Step
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL spatial; LOAD spatial;")
dbExecute(
  con,
  sprintf(
    "CREATE TABLE p AS SELECT * EXCLUDE(geometry), ST_GeomFromWKB(geometry) AS geom FROM '%s'",
    addr_pq
  )
)
dbExecute(
  con,
  sprintf(
    "CREATE TABLE c AS SELECT * EXCLUDE(geometry), ST_GeomFromWKB(geometry) AS geom FROM '%s'",
    county_pq
  )
)
dbExecute(con, "CREATE INDEX idx_c_geom ON c USING RTREE (geom)")

# 2. Analysis Benchmark
bm_analysis <- bench::mark(
  validation = {
    sql <- "
      SELECT c.FIPS_STR, COUNT(a.OBJECTID)
      FROM p a, c
      WHERE ST_Within(a.geom, c.geom)
      GROUP BY c.FIPS_STR
    "
    res <- dbGetQuery(con, sql)
  },
  iterations = 1,
  check = FALSE
)
log_result("duckdb", "R", "Validation (Join)", bm_analysis)

# --- 3. EXPORT VALIDATION STATS (New for Slides) ---
message("Generating validation statistics...")
sql_diff <- "
WITH attr_counts AS (
    SELECT CountyID, COUNT(*) as count_attr
    FROM p GROUP BY CountyID
),
spatial_counts AS (
    SELECT c.FIPS_STR, COUNT(a.OBJECTID) as count_spatial
    FROM p a, c
    WHERE ST_Within(a.geom, c.geom)
    GROUP BY c.FIPS_STR
)
SELECT
    COALESCE(a.CountyID, s.FIPS_STR) as CountyID,
    COALESCE(a.count_attr, 0) as count_attr,
    COALESCE(s.count_spatial, 0) as count_spatial,
    (COALESCE(a.count_attr, 0) - COALESCE(s.count_spatial, 0)) as diff
FROM attr_counts a
FULL OUTER JOIN spatial_counts s ON a.CountyID = s.FIPS_STR
ORDER BY ABS(diff) DESC
LIMIT 10;
"
stats <- dbGetQuery(con, sql_diff)
write_csv(stats, "_results/validation_stats.csv")

dbDisconnect(con)
