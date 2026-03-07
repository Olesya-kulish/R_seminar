# Comparison: R Results vs. Stata Expected Outputs
# This script validates your R replication against the Stata code logic

library(dplyr)
library(readr)

# Load your R outputs
table_iv_all <- read.csv("output/table_IV_panelA_all_measures.csv")
table_iii_a <- read.csv("output/table_III_A_cols_1_4.csv")
summary_stats_1 <- read.csv("output/summary_stats_city1.csv")
table_ii <- read.csv("output/table_II_cols_1_2_5.csv")

# ============================================================================
# VALIDATION 1: TABLE IV, PANEL A - Observation Counts
# ============================================================================
# Stata code (line 434): ppmlhdfe real_pc_outlay ... if check<0.2 & check>-0.2
# Expected observation counts from Stata should be same for all leverage measures

cat("\n=== TABLE IV, PANEL A: OBSERVATION COUNTS ===\n")
cat("This table has 4 leverage measures. Stata uses: if check<0.2 & check>-0.2\n")
cat("If your N values differ significantly by measure, check the filter.\n\n")

print(table_iv_all %>% select(treatment, n) %>% distinct())

cat("\nExpected: All should be ~3829 if matching Stata's sample restrictions\n")
cat("Current: See above - note the variation by leverage measure\n")

# ============================================================================
# VALIDATION 2: TABLE III, PANEL A - DiD Coefficients Direction & Magnitude
# ============================================================================
cat("\n=== TABLE III, PANEL A: COEFFICIENT SIGNS & MAGNITUDES ===\n")
cat("All leverage × period interactions should be negative (financial distress effect)\n")
cat("Coefficients should be largest for 1934-1938 period (peak depression impact)\n\n")

print(table_iii_a %>% select(Variable, starts_with("Col")))

# ============================================================================
# VALIDATION 3: SUMMARY STATISTICS - Data Consistency
# ============================================================================
cat("\n=== SUMMARY STATISTICS: DATA VALIDATION ===\n")
cat("Check: Do means/SDs look reasonable for 1924-1943 panel?\n")
cat("Capital outlays mean should be ~12.5 (per capita, current dollars)\n")
cat("Total service payments mean should be ~48.75\n\n")

print(summary_stats_1 %>% select(Variable, N, Mean, SD, Median) %>% head(10))

# ============================================================================
# VALIDATION 4: TABLE II - Leverage Determinants
# ============================================================================
cat("\n=== TABLE II: LEVERAGE DETERMINANTS (1929 cross-section) ===\n")
cat("Population coefficient should be positive for all leverage measures\n")
cat("Expected direction: Higher pop → Higher leverage\n")
cat("Sample: Col1 N=697 (bonds), Col2-5 N=608 (missing variables)\n\n")

print(table_ii)

# ============================================================================
# KEY CHECKS FOR STATA EQUIVALENCE
# ============================================================================
cat("\n=== DIAGNOSTIC CHECKLIST ===\n")

# Check 1: Sample sizes
n_table_iv <- mean(table_iv_all$n)
cat(sprintf("1. Table IV avg N: %d (Expected ~3829)\n", n_table_iv))

# Check 2: Coefficient range (all should be negative in Table III)
table_iii_coefs <- as.numeric(table_iii_a$`Col 4`[1:4])
negative_coefs <- sum(table_iii_coefs < 0)
cat(sprintf("2. Table III negative coefficients: %d/4 (Expected 4/4)\n", negative_coefs))

# Check 3: Summary stats N consistency
n_summary <- as.numeric(summary_stats_1$N[1])
cat(sprintf("3. Summary stats N: %d (Expected ~12,602 for full balanced panel)\n", n_summary))

# Check 4: Standard errors reasonableness
avg_se_iv <- mean(table_iv_all$se)
cat(sprintf("4. Table IV avg SE: %.4f (Should be 0.05-0.15)\n", avg_se_iv))

cat("\n=== NEXT STEPS ===\n")
cat("1. If N differs by >50: Check filter conditions (check<0.2, complete cases)\n")
cat("2. If coefficients have wrong sign: Check reference category in post_detail\n")
cat("3. If SEs too large: May indicate clustering/FE issues\n")
cat("4. If summary stats don't match: Check variable transformations (log, per capita)\n")
