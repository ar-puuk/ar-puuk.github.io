# ═══════════════════════════════════════════════════════════════════════════════
# BENCHMARK 01: Legacy R Stack (sf + CSV/Shapefile)
# ═══════════════════════════════════════════════════════════════════════════════
# FIX (vs previous version):
#
#   force(expr) promise-caching bug:
#     In R, function arguments are lazily evaluated promises whose result is
#     CACHED after the first evaluation. The previous measure_rss() used
#     force(expr) inside a loop, which meant the expression only actually ran
#     on iteration 1 — subsequent iterations timed the cost of returning a
#     cached NULL value (~0 µs). For ITERATIONS > 1 this produced completely
#     wrong median timings.
#
#     Fix: measure_rss() now accepts a function (fn) instead of an expression,
#     and calls fn() on each iteration. Functions are re-invoked every call.
#     Call sites change from measure_rss({ ... }) to measure_rss(function() { ... }).
#
# Author: Pukar Bhandari
# ═══════════════════════════════════════════════════════════════════════════════

library(sf)
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

# Helper: accepts a FUNCTION (not a bare expression) and calls it each iteration.
# Using fn() instead of force(expr) ensures the body re-executes every time.
measure_rss <- function(fn, iterations = 1L) {
  times <- numeric(iterations)
  mem_deltas <- numeric(iterations)

  for (i in seq_len(iterations)) {
    gc(verbose = FALSE)
    mem_before <- ps::ps_memory_info()[["rss"]]
    t_start <- proc.time()[["elapsed"]]

    fn() # Re-invoked on every iteration — no caching

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

addr_csv <- "_data/utah_addresses.csv"
county_shp <- "_data/utah_counties.shp"

message("────────────────────────────────────────────────────────────")
message("Running: BENCHMARK 01 - R (sf) Legacy Stack")
message("────────────────────────────────────────────────────────────")

# ───────────────────────────────────────────────────────────────────────────────
## 2. I/O BENCHMARK (Data Load) ----
# ───────────────────────────────────────────────────────────────────────────────

res_io <- measure_rss(
  function() {
    pts <- read_csv(
      addr_csv,
      col_types = cols(CountyID = col_character()),
      show_col_types = FALSE
    ) |>
      st_as_sf(coords = c("x", "y"), crs = 4326)

    cnt <- st_read(county_shp, quiet = TRUE) |>
      st_transform(4326)
  },
  iterations = ITERATIONS
)

log_result("sf", "R", "Load Data", res_io$time_sec, res_io$mem_mb)
message(sprintf(
  "  Load Data: %.3fs | %.1f MB RSS delta",
  res_io$time_sec,
  res_io$mem_mb
))

# ───────────────────────────────────────────────────────────────────────────────
## 3. RELOAD DATA FOR ANALYSIS PHASE (not timed) ----
# ───────────────────────────────────────────────────────────────────────────────

pts <- read_csv(
  addr_csv,
  col_types = cols(CountyID = col_character()),
  show_col_types = FALSE
) |>
  st_as_sf(coords = c("x", "y"), crs = 4326)

cnt <- st_read(county_shp, quiet = TRUE) |>
  st_transform(4326)

# ───────────────────────────────────────────────────────────────────────────────
## 4. ANALYSIS BENCHMARK (Spatial Join) ----
# ───────────────────────────────────────────────────────────────────────────────

res_analysis <- measure_rss(
  function() {
    res_attr <- pts |>
      st_drop_geometry() |>
      count(CountyID)

    res_spatial <- st_join(pts, cnt, join = st_within) |>
      st_drop_geometry() |>
      count(FIPS_ST)
  },
  iterations = ITERATIONS
)

log_result(
  "sf",
  "R",
  "Validation (Join)",
  res_analysis$time_sec,
  res_analysis$mem_mb
)
message(sprintf(
  "  Validation (Join): %.3fs | %.1f MB RSS delta",
  res_analysis$time_sec,
  res_analysis$mem_mb
))

# ───────────────────────────────────────────────────────────────────────────────
## 5. CLEANUP ----
# ───────────────────────────────────────────────────────────────────────────────

rm(pts, cnt, res_attr, res_spatial)

message("────────────────────────────────────────────────────────────")
message("BENCHMARK 01 Complete!")
message("────────────────────────────────────────────────────────────")
