# ═══════════════════════════════════════════════════════════════════════════════
# ORCHESTRATION SCRIPT: Benchmark Suite Runner
# ═══════════════════════════════════════════════════════════════════════════════
# FIX NOTES:
#   - Replaced system2("Rscript", ...) with callr::rscript() to avoid the
#     Windows deadlock that occurs when system2() is called inside a knitr
#     session (knitr captures stdout/stderr via R connections; child processes
#     inherit those connections and can block waiting for the buffer to drain).
#   - ITERATIONS is passed to sub-scripts via environment variable, same as
#     before, but now also works for R scripts through callr's env argument.
#   - Added error handling that captures stderr for clearer diagnostics.
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────────
## CONFIGURATION ----
# ───────────────────────────────────────────────────────────────────────────────

if (!exists("ITERATIONS")) {
  ITERATIONS <- 1
}

# ───────────────────────────────────────────────────────────────────────────────
## HELPER FUNCTIONS ----
# ───────────────────────────────────────────────────────────────────────────────

# FIX: Use callr::rscript() instead of system2("Rscript", ...)
#
# Why: system2() called from within a knitr session on Windows can deadlock
# because the child process inherits knitr's captured R connections.
# callr::rscript() runs in a completely separate R session with its own
# stdout/stderr handling, avoiding this issue entirely.
run_r_script <- function(script_path) {
  message(paste("--- Running R:", script_path, "---"))

  if (!requireNamespace("callr", quietly = TRUE)) {
    stop(
      "Package 'callr' is required to safely run sub-scripts from within ",
      "a knitr session. Install it with: install.packages('callr')"
    )
  }

  # Pass ITERATIONS and working directory to the subprocess
  callr::rscript(
    script = script_path,
    wd = getwd(), # Inherit the working directory (spatial-benchmark/)
    env = c(
      BENCHMARK_ITERATIONS = as.character(ITERATIONS),
      # Ensure the renv library is loaded in the subprocess
      RENV_PATHS_ROOT = Sys.getenv("RENV_PATHS_ROOT", unset = "")
    ),
    stdout = "", # Stream stdout to console
    stderr = "2>&1" # Merge stderr into stdout for diagnostics
  )
  message(paste("--- Done:", script_path, "---\n"))
}

run_py_script <- function(script_path) {
  message(paste("--- Running Python:", script_path, "---"))
  Sys.setenv(BENCHMARK_ITERATIONS = ITERATIONS)

  # Let uv handle the execution and environment isolation
  exit_code <- system2("uv", args = c("run", script_path))

  if (exit_code != 0) {
    stop(paste("Python script failed with exit code", exit_code, ":", script_path))
  }
  message(paste("--- Done:", script_path, "---\n"))
}

# ───────────────────────────────────────────────────────────────────────────────
## SETUP ----
# ───────────────────────────────────────────────────────────────────────────────

message(paste("[Init] Running with ITERATIONS =", ITERATIONS))

# Create directories
if (!dir.exists("_results")) {
  dir.create("_results", recursive = TRUE)
}
if (!dir.exists("_data")) {
  dir.create("_data", recursive = TRUE)
}

# Initialize results CSV with header
results_csv <- "_results/benchmark_results.csv"
cat("system,language,operation,time_sec,memory_mb\n", file = results_csv)
message("[Init] Results CSV initialized: ", results_csv, "\n")

# ───────────────────────────────────────────────────────────────────────────────
## EXECUTE BENCHMARKS ----
# ───────────────────────────────────────────────────────────────────────────────

# Setup Data (if script exists — skips download if files already present)
if (file.exists("_scripts/00_setup_data.R")) {
  run_r_script("_scripts/00_setup_data.R")
}

# Run Benchmarks
run_r_script("_scripts/01_bench_sf.R")
run_r_script("_scripts/02_bench_duckdb.R")
run_py_script("_scripts/03_bench_geopandas.py")
run_py_script("_scripts/04_bench_duckdb.py")
run_r_script("_scripts/05_bench_sedonadb.R")
# run_py_script("_scripts/06_bench_sedonadb.py", python_exec)

message("─────────────────────────────────────────────────────────")
message("SUCCESS: All benchmarks complete.")
message("  Results written to: _results/benchmark_results.csv")
message("─────────────────────────────────────────────────────────")
