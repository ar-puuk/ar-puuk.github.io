library(sf)
library(dplyr)
library(readr)
library(bench)

# Output to _results folder
results_csv <- "_results/benchmark_results.csv"

# Helper to log results
log_result <- function(sys, lang, op, bm) {
  # bm is the bench::mark object
  time_sec <- as.numeric(bm$median) # Median time in seconds
  mem_mb <- as.numeric(bm$mem_alloc) / 1024 / 1024 # Convert Bytes to MB

  cat(
    sprintf("%s,%s,%s,%.4f,%.2f\n", sys, lang, op, time_sec, mem_mb),
    file = results_csv,
    append = TRUE
  )
}

# Paths
addr_csv <- "_data/utah_addresses.csv"
county_shp <- "_data/utah_counties.shp"

message("--- 01: R (sf) Legacy ---")

# 1. I/O Benchmark
# We use bench::mark with iterations=1 to capture the resource usage of a single run
bm_io <- bench::mark(
  load_data = {
    pts <- read_csv(
      addr_csv,
      col_types = cols(CountyID = col_character()),
      show_col_types = FALSE
    ) |>
      st_as_sf(coords = c("x", "y"), crs = 4326)
    cnt <- st_read(county_shp, quiet = TRUE) |> st_transform(4326)
  },
  iterations = 1,
  check = FALSE
)
log_result("sf", "R", "Load Data", bm_io)

# Re-load objects for the next step (bench::mark runs in its own env mostly)
pts <- read_csv(
  addr_csv,
  col_types = cols(CountyID = col_character()),
  show_col_types = FALSE
) |>
  st_as_sf(coords = c("x", "y"), crs = 4326)
cnt <- st_read(county_shp, quiet = TRUE) |> st_transform(4326)

# 2. Analysis Benchmark
bm_analysis <- bench::mark(
  validation = {
    # Attribute Count
    res_attr <- pts |> st_drop_geometry() |> count(CountyID)
    # Spatial Join
    res_spatial <- st_join(pts, cnt, join = st_within) |>
      st_drop_geometry() |>
      count(FIPS_ST)
  },
  iterations = 1,
  check = FALSE
)
log_result("sf", "R", "Validation (Join)", bm_analysis)
