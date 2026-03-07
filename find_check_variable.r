# Find the correct "check" variable in the data

library(haven)
library(dplyr)

df <- read_dta('data/replication-data-city.dta')

cat("\n=== SEARCHING FOR 'CHECK' VARIABLE ===\n\n")

# Get all variable names
all_vars <- names(df)

cat("Total variables in dataset:", length(all_vars), "\n\n")

# Search for variables containing "check"
check_vars <- all_vars[grepl("check", all_vars, ignore.case = TRUE)]

cat("Variables containing 'check':\n")
if (length(check_vars) > 0) {
  for (v in check_vars) {
    cat("  -", v, "\n")
  }
} else {
  cat("  NO VARIABLES FOUND with 'check' in the name!\n")
}

cat("\n")

# Search for variables containing "moody"
moody_vars <- all_vars[grepl("moody", all_vars, ignore.case = TRUE)]

cat("Variables containing 'moody':\n")
if (length(moody_vars) > 0) {
  for (v in moody_vars) {
    cat("  -", v, "\n")
  }
} else {
  cat("  NO VARIABLES FOUND with 'moody' in the name!\n")
}

cat("\n")

# Show first 50 variable names to help identify
cat("First 50 variables in the dataset:\n")
cat("(Looking for anything that might be the 'check' filter variable)\n\n")
for (i in 1:min(50, length(all_vars))) {
  cat(sprintf("%2d. %s\n", i, all_vars[i]))
}

cat("\n")

# Check specifically for the variables we expected
cat("=== SPECIFIC VARIABLE CHECK ===\n")
cat("'check' exists:", "check" %in% all_vars, "\n")
cat("'check_moody' exists:", "check_moody" %in% all_vars, "\n")

cat("\n=== NEXT STEPS ===\n")
cat("1. Look at the variables listed above\n")
cat("2. Find one that looks like it might filter outliers\n")
cat("3. Common patterns: check*, *_check, *_std, *_outlier, *_filter\n")
cat("4. The Stata code says: if check<0.2 & check>-0.2\n")
cat("5. This variable should have values roughly between -1 and 1\n")
