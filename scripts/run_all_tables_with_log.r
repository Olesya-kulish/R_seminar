############################################################
# Master replication runner (automated)
#
# Purpose:
# 1) Load the original replication-package datasets first.
# 2) Run all table scripts in one go.
# 3) Save a complete execution log using sink().
############################################################

required_pkgs <- c("haven", "dplyr", "fixest", "tibble", "purrr", "flextable")
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  stop(
    paste0(
      "Missing packages: ", paste(missing_pkgs, collapse = ", "),
      "\nInstall them first with install.packages(c(",
      paste0("\"", missing_pkgs, "\"", collapse = ", "),
      "))"
    )
  )
}

# Ensure output folder exists before logging
if (!dir.exists("output")) dir.create("output", recursive = TRUE)

log_file <- file.path("output", "run_log.txt")
status_file <- file.path("output", "run_status.csv")

# Start transcript log and mirror to console
sink(log_file, split = TRUE)
on.exit({
  sink()
}, add = TRUE)

cat("============================================================\n")
cat("R REPLICATION RUN LOG\n")
cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("Working directory:", normalizePath(getwd(), winslash = "/"), "\n")
cat("============================================================\n\n")

# Requirement from instructor: start by loading original replication data
cat("[STEP 1] Loading original replication-package data...\n")
city_path <- file.path("data", "replication-data-city.dta")
micro_path <- file.path("data", "replication-data-micro.dta")

if (!file.exists(city_path) || !file.exists(micro_path)) {
  stop("Required .dta files not found in data/. Please run from the project root.")
}

city_data <- haven::read_dta(city_path)
micro_data <- haven::read_dta(micro_path)

cat("Loaded city data:", nrow(city_data), "rows x", ncol(city_data), "cols\n")
cat("Loaded micro data:", nrow(micro_data), "rows x", ncol(micro_data), "cols\n\n")

cat("[STEP 2] Running table scripts...\n")
script_list <- c(
  "scripts/Table_1.r",
  "scripts/Table_II.r",
  "scripts/Table_III_A.r",
  "scripts/Table_IV_PanelAB.r"
)

run_results <- lapply(script_list, function(s) {
  cat("\n------------------------------------------------------------\n")
  cat("Running:", s, "\n")
  cat("------------------------------------------------------------\n")

  started <- Sys.time()
  out <- tryCatch({
    source(s, echo = FALSE, local = new.env(parent = globalenv()))
    list(ok = TRUE, message = "OK")
  }, error = function(e) {
    list(ok = FALSE, message = conditionMessage(e))
  })
  ended <- Sys.time()

  cat("Result:", if (out$ok) "SUCCESS" else "FAILED", "\n")
  if (!out$ok) cat("Error:", out$message, "\n")

  data.frame(
    script = s,
    success = out$ok,
    message = out$message,
    started_at = format(started, "%Y-%m-%d %H:%M:%S"),
    ended_at = format(ended, "%Y-%m-%d %H:%M:%S"),
    stringsAsFactors = FALSE
  )
})

status_df <- do.call(rbind, run_results)
write.csv(status_df, status_file, row.names = FALSE)

cat("\n[STEP 3] Session info\n")
print(sessionInfo())

cat("\n============================================================\n")
cat("Run finished.\n")
cat("Log file:", normalizePath(log_file, winslash = "/"), "\n")
cat("Status file:", normalizePath(status_file, winslash = "/"), "\n")
cat("============================================================\n")
