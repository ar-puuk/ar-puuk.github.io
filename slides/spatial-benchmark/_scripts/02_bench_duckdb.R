library(duckdb)
library(dplyr)
library(bench)
library(arrow)
library(geoarrow)
library(DBI)

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

message("--- 02: R (DuckDB) Modern ---")

# 1. I/O Benchmark
bm_io <- bench::mark(
  load_data = {
    con <- dbConnect(duckdb())
    dbExecute(con, "INSTALL spatial; LOAD spatial;")
    DBI::dbExecute(con, "CALL register_geoarrow_extensions()")
    dbExecute(
      con,
      sprintf("CREATE OR REPLACE VIEW p AS SELECT * FROM '%s'", addr_pq)
    )
    dbExecute(
      con,
      sprintf("CREATE OR REPLACE VIEW c AS SELECT * FROM '%s'", county_pq)
    )
  },
  iterations = 1,
  check = FALSE
)
log_result("duckdb", "R", "Load Data", bm_io)

# Re-connect for analysis step
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL spatial; LOAD spatial;")
DBI::dbExecute(con, "CALL register_geoarrow_extensions()")
dbExecute(
  con,
  sprintf("CREATE OR REPLACE VIEW p AS SELECT * FROM '%s'", addr_pq)
)
dbExecute(
  con,
  sprintf("CREATE OR REPLACE VIEW c AS SELECT * FROM '%s'", county_pq)
)

# 2. Analysis Benchmark
bm_analysis <- bench::mark(
  validation = {
    sql <- "
      SELECT c.FIPS_STR, COUNT(a.OBJECTID)
      FROM p a, c
      WHERE ST_Within(
        ST_Point(a.geometry.x, a.geometry.y),
        CAST(c.geometry AS GEOMETRY)
      )
      GROUP BY c.FIPS_STR
    "
    res <- dbGetQuery(con, sql)
  },
  iterations = 1,
  check = FALSE
)
log_result("duckdb", "R", "Validation (Join)", bm_analysis)

dbDisconnect(con)
