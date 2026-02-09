# ═══════════════════════════════════════════════════════════════════════════════
# ORCHESTRATION SCRIPT: Benchmark Suite Runner
# ═══════════════════════════════════════════════════════════════════════════════
# Based on the old working version, simplified and portable
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────────
## CONFIGURATION ----
# ───────────────────────────────────────────────────────────────────────────────

# Iterations (can be set before sourcing this script)
if (!exists("ITERATIONS")) {
  ITERATIONS <- 1
}

# ───────────────────────────────────────────────────────────────────────────────
## HELPER FUNCTIONS ----
# ───────────────────────────────────────────────────────────────────────────────

run_r_script <- function(script_path) {
  message(paste("--- Running R:", script_path, "---"))
  if (!file.exists("../../renv.lock")) {
    warning("renv.lock not found. Using system library.")
    cmd <- paste0("source('", script_path, "')")
  } else {
    cmd <- paste0("renv::load('../../'); source('", script_path, "')")
  }
  exit_code <- system2("Rscript", args = c("-e", shQuote(cmd)))
  if (exit_code != 0) stop(paste("Script failed:", script_path))
}

run_py_script <- function(script_path, python_path) {
  message(paste("--- Running Python:", script_path, "---"))

  # Set iterations for Python scripts
  Sys.setenv(BENCHMARK_ITERATIONS = ITERATIONS)

  exit_code <- system2(python_path, args = c(script_path))
  if (exit_code != 0) stop(paste("Script failed:", script_path))
}

# ───────────────────────────────────────────────────────────────────────────────
## SETUP ----
# ───────────────────────────────────────────────────────────────────────────────

message(paste("[Init] Running with ITERATIONS =", ITERATIONS))

# Resolve Python path (portable across devices)
python_exec <- "python"

if (file.exists("../../env/python.exe")) {
  python_exec <- normalizePath("../../env/python.exe")
} else if (file.exists("../../env/bin/python")) {
  python_exec <- normalizePath("../../env/bin/python")
}

message(paste("[Init] Using Python:", python_exec))

# Create directories
if (!dir.exists("_results")) {
  dir.create("_results")
}
if (!dir.exists("_data")) {
  dir.create("_data")
}

# Initialize results CSV
results_csv <- "_results/benchmark_results.csv"
cat("system,language,operation,time_sec,memory_mb\n", file = results_csv)
message("")

# ───────────────────────────────────────────────────────────────────────────────
## EXECUTE BENCHMARKS ----
# ───────────────────────────────────────────────────────────────────────────────

# Setup Data (if exists)
if (file.exists("_scripts/00_setup_data.R")) {
  run_r_script("_scripts/00_setup_data.R")
}

# Run Benchmarks
run_r_script("_scripts/01_bench_sf.R")
run_r_script("_scripts/02_bench_duckdb.R")
run_py_script("_scripts/03_bench_geopandas.py", python_exec)
run_py_script("_scripts/04_bench_duckdb.py", python_exec)

message("─────────────────────────────────────────────────────────")
message("SUCCESS: Benchmarks Complete!")
message("─────────────────────────────────────────────────────────")

# ═══════════════════════════════════════════════════════════════════════════════
# END OF ORCHESTRATION SCRIPT
# ═══════════════════════════════════════════════════════════════════════════════
