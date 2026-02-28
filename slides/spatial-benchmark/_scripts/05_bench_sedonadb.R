# ═══════════════════════════════════════════════════════════════════════════════
# BENCHMARK 05: Modern R Stack (Apache SedonaDB + Parquet)
# ═══════════════════════════════════════════════════════════════════════════════
# Architecture notes:
#   - SedonaDB is an embedded Rust/DataFusion engine — no JVM, no Spark.
#   - No explicit INSTALL/LOAD step — spatial functions ship with the package.
#   - No explicit index creation — DataFusion handles spatial indexing internally.
#   - sd_read_parquet() + sd_to_view() is LAZY: no data is scanned until
#     sd_collect() fires. "Load Data" times view registration only (~0.01s).
#     Actual Parquet scan happens during "Validation (Join)".
#
# Fixes applied:
#   FIX 1 — fn() pattern in measure_rss():
#     R promises cache after first evaluation — force(expr) in a loop only runs
#     the body on iteration 1. fn() re-executes every iteration.
#
#   FIX 2 — No "SELECT * EXCLUDE":
#     DataFusion does not support DuckDB's EXCLUDE extension.
#     All columns named explicitly using schemas confirmed from Parquet files.
#
#   FIX 3 — Double-quoted identifiers throughout:
#     DataFusion is CASE-SENSITIVE. Unquoted identifiers are lowercased at parse
#     time (OBJECTID → objectid → schema error). All column references use
#     double-quotes to preserve original case.
#
#   FIX 4 — ps::ps_memory_info()[["rss"]] not $rss:
#     On Windows, ps_memory_info() returns a named numeric vector (not a list).
#     $ accessor throws "invalid for atomic vectors". [["rss"]] works on both.
#
# Author: Pukar Bhandari
# ═══════════════════════════════════════════════════════════════════════════════

library(sedonadb)
library(dplyr)
library(readr)
library(ps)

results_csv <- "_results/benchmark_results.csv"

ITERATIONS <- as.integer(
  Sys.getenv(
    "BENCHMARK_ITERATIONS",
    unset = ifelse(exists("ITERATIONS"), as.character(ITERATIONS), "1")
  )
)

# FIX 1 + FIX 4
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
message("Running: BENCHMARK 05 - R (SedonaDB) Modern Stack")
message("────────────────────────────────────────────────────────────")

# ───────────────────────────────────────────────────────────────────────────────
## 2. I/O BENCHMARK — Load Data ----
# ───────────────────────────────────────────────────────────────────────────────
#
# FIX 2 + FIX 3: Explicit quoted column lists from actual Parquet schemas.
# Schemas confirmed from live Parquet files:
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
#
# LAZY EVALUATION NOTE:
#   sd_read_parquet() + sd_to_view() registers a view definition — no data read.
#   "Load Data" timing is ~0.01s (view registration overhead only).
#   Actual Parquet scan fires during "Validation (Join)" via sd_collect().
# ───────────────────────────────────────────────────────────────────────────────

res_io <- measure_rss(
  function() {
    sd_read_parquet(addr_pq) |> sd_to_view("addr_raw", overwrite = TRUE)
    sd_read_parquet(county_pq) |> sd_to_view("county_raw", overwrite = TRUE)

    sd_sql(
      '
    SELECT
      "OBJECTID", "AddSystem", "UTAddPtID", "FullAdd", "AddNum",
      "AddNumSuffix", "PrefixDir", "StreetName", "StreetType", "SuffixDir",
      "LandmarkName", "Building", "UnitType", "UnitID", "City", "ZipCode",
      "CountyID", "State", "PtLocation", "PtType", "Structure", "ParcelID",
      "AddSource", "LoadDate", "USNG",
      ST_GeomFromWKB(geometry) AS geom
    FROM addr_raw
  '
    ) |>
      sd_to_view("p", overwrite = TRUE)

    sd_sql(
      '
    SELECT
      "OBJECTID", "COUNTYNBR", "ENTITYNBR", "ENTITYYR", "NAME", "FIPS",
      "STATEPLANE", "POP_LASTCENSUS", "POP_CURRESTIMATE", "GlobalID",
      "FIPS_STR", "COLOR4", "Shape__Area", "Shape__Length", "CLASS",
      ST_GeomFromWKB(geometry) AS geom
    FROM county_raw
  '
    ) |>
      sd_to_view("c", overwrite = TRUE)
  },
  iterations = ITERATIONS
)

log_result("sedonadb", "R", "Load Data", res_io$time_sec, res_io$mem_mb)
message(sprintf(
  "  Load Data: %.3fs | %.1f MB RSS delta",
  res_io$time_sec,
  res_io$mem_mb
))

# ───────────────────────────────────────────────────────────────────────────────
## 3. WARMUP QUERY ----
# ───────────────────────────────────────────────────────────────────────────────

message("Running warmup query (not timed)...")

invisible(
  sd_sql(
    '
    SELECT c."FIPS_STR", COUNT(*) AS point_count
    FROM c
    INNER JOIN p a ON ST_Intersects(a.geom, c.geom)
    GROUP BY c."FIPS_STR"
  '
  ) |>
    sd_collect()
)

message("Warmup complete. Starting timed benchmark...")

# ───────────────────────────────────────────────────────────────────────────────
## 4. ANALYSIS BENCHMARK — Spatial Join ----
# ───────────────────────────────────────────────────────────────────────────────
#
# COUNT(*) used instead of COUNT(a."OBJECTID") — semantically equivalent for
# counting matched rows, and avoids any residual case-sensitivity concerns.
# ───────────────────────────────────────────────────────────────────────────────

res_join <- measure_rss(
  function() {
    sd_sql(
      '
    SELECT c."FIPS_STR", COUNT(*) AS point_count
    FROM c
    INNER JOIN p a ON ST_Intersects(a.geom, c.geom)
    GROUP BY c."FIPS_STR"
  '
    ) |>
      sd_collect()
  },
  iterations = ITERATIONS
)

log_result(
  "sedonadb",
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
## 5. CLEANUP ----
# ───────────────────────────────────────────────────────────────────────────────

sd_drop_view("p")
sd_drop_view("c")
sd_drop_view("addr_raw")
sd_drop_view("county_raw")

message("────────────────────────────────────────────────────────────")
message("BENCHMARK 05 Complete!")
message("────────────────────────────────────────────────────────────")
