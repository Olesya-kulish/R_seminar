# THOROUGH SEARCH: Find the 'check' variable or similar

library(haven)
library(dplyr)

df <- read_dta('data/replication-data-city.dta')

cat("\n=== SEARCHING FOR 'check' OR SIMILAR VARIABLES ===\n\n")

# Get all variable names
all_vars <- names(df)

# Case-insensitive search for 'check'
check_vars <- all_vars[grepl("check", all_vars, ignore.case = TRUE)]
cat("Variables containing 'check' (case-insensitive):\n")
if (length(check_vars) > 0) {
  for (v in check_vars) {
    cat("  -", v, "\n")
  }
} else {
  cat("  NONE FOUND\n")
}

cat("\n")

# Search for anything that might be a filter/outlier variable
possible_filters <- all_vars[grepl("outlier|filter|trim|exclude|drop|flag", all_vars, ignore.case = TRUE)]
cat("Variables that might be filters:\n")
if (length(possible_filters) > 0) {
  for (v in possible_filters) {
    cat("  -", v, "\n")
  }
} else {
  cat("  NONE FOUND\n")
}

cat("\n")

# Look for variables with values in range -0.2 to 0.2 (like check should be)
cat("Looking for variables with most values between -0.2 and 0.2...\n")
cat("(This might be 'check' even if it has a different name)\n\n")

numeric_vars <- names(df)[sapply(df, is.numeric)]
candidates <- c()

for (v in numeric_vars) {
  vals <- df[[v]]
  if (!all(is.na(vals))) {
    prop_in_range <- mean(vals >= -0.2 & vals <= 0.2, na.rm = TRUE)
    if (prop_in_range > 0.5 & prop_in_range < 1.0) {  # Most but not all in range
      min_val <- min(vals, na.rm=TRUE)
      max_val <- max(vals, na.rm=TRUE)
      if (min_val < 0 & max_val > 0) {  # Crosses zero
        candidates <- c(candidates, v)
      }
    }
  }
}

if (length(candidates) > 0) {
  cat("CANDIDATE VARIABLES (might be 'check'):\n")
  for (v in candidates) {
    vals <- df[[v]]
    cat(sprintf("  %-30s: %.1f%% in [-0.2,0.2], min=%.3f, max=%.3f\n",
                v,
                100*mean(vals >= -0.2 & vals <= 0.2, na.rm=TRUE),
                min(vals, na.rm=TRUE),
                max(vals, na.rm=TRUE)))
  }
} else {
  cat("No obvious candidates found.\n")
}

cat("\n=== HYPOTHESIS: 'check' might be 'check_moody' ===\n\n")

if ("check_moody" %in% names(df)) {
  cat("check_moody statistics:\n")
  vals <- df$check_moody
  cat(sprintf("  Min: %.4f\n", min(vals, na.rm=TRUE)))
  cat(sprintf("  Max: %.4f\n", max(vals, na.rm=TRUE)))
  cat(sprintf("  Mean: %.4f\n", mean(vals, na.rm=TRUE)))
  cat(sprintf("  Proportion in [-0.2, 0.2]: %.1f%%\n", 
              100*mean(vals >= -0.2 & vals <= 0.2, na.rm=TRUE)))
  
  cat("\nThis COULD be the 'check' variable Stata refers to!\n")
  cat("In the Stata code, 'check' might just be shorthand for 'check_moody'.\n\n")
}

cat("\n=== CRITICAL INSIGHT ===\n\n")
cat("Looking at the Stata code structure:\n")
cat("Line 439: foreach a in bonds_to_assess29_lev int_to_rev29_lev...\n")
cat("Line 440:   gen test_moody = `a'_moody_std\n")
cat("Line 443:   ppmlhdfe ... if check<0.2 & check>-0.2\n")
cat("Line 461:   drop test_moody test\n\n")

cat("NOTICE: It drops both 'test_moody' AND 'test' at the end.\n")
cat("But we never saw 'gen test' in the Table IV code!\n")
cat("This suggests 'test' might be created ELSEWHERE in the loop.\n\n")

cat("WAIT - Look more carefully at line 443!\n")
cat("The Stata model uses: c.test_moody (not c.test)\n")
cat("So 'test' is unrelated to the model!\n\n")

cat("CONCLUSION:\n")
cat("The 'check' variable filter is INDEPENDENT of the leverage measure.\n")
cat("It's probably check_moody (or possibly doesn't exist if it was\n")
cat("created earlier in the Stata session and not saved to the .dta file).\n\n")

cat("===  ACTION ITEMS ===\n\n")
cat("Since your coefficient has the WRONG SIGN, the problem is NOT\n")
cat("the 'check' filter. The problem is something more fundamental:\n\n")

cat("1. Are you using the SAME leverage variable as Stata?\n")
cat("   Stata: debt_to_rev29_lev_moody_std\n")
cat("   You should use: debt_to_rev29_lev_moody_std\n\n")

cat("2. Is your reference period correct?\n")
cat("   Stata: ib2.post_detail (reference = period 2 = 1927-1928)\n")
cat("   You should use: ref = 2 in i(post_detail, leverage, ref=2)\n\n")

cat("3. Check your model specification EXACTLY matches Stata:\n")
cat("   ppmlhdfe real_pc_outlay ib2.post_detail##c.test_moody\n")
cat("   ib1928.year c.pop_30##i.year c.pop_20_30##i.year\n")
cat("   real_pc_rev_total_log L1.real_pc_rev_total_log\n")
cat("   i.year#i.region_, absorb(id_ year) cl(id_)\n\n")

cat("Let me create a diagnostic to test this...\n")
