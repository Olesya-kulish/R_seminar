# Detailed analysis: Which variable is causing the 81-obs loss?

library(haven)
library(dplyr)

df_city <- read_dta('data/replication-data-city.dta')

cat("\n")
cat(paste(rep("=", 70), collapse=""), "\n")
cat("DETAILED ANALYSIS: Finding the Exact Source of 81 Missing Observations\n")
cat(paste(rep("=", 70), collapse=""), "\n\n")

# Replicate the filtering up to where we have the discrepancy
df <- df_city %>%
  mutate(leverage = debt_to_rev29_lev_moody_std) %>%
  filter(!(year %in% c(1939, 1940))) %>%
  filter(check_moody < 0.2 & check_moody > -0.2) %>%
  mutate(
    post_detail = case_when(
      year %in% 1924:1926 ~ 1,
      year %in% 1927:1928 ~ 2,
      year %in% 1929:1933 ~ 3,
      year %in% 1934:1938 ~ 4,
      year %in% 1941:1943 ~ 5,
      TRUE ~ NA_real_
    )
  ) %>%
  arrange(id_, year) %>%
  group_by(id_) %>%
  mutate(L_real_pc_rev_total_log = lag(real_pc_rev_total_log)) %>%
  ungroup()

# Start from the sample after basic filters
baseline <- df %>% filter(!is.na(post_detail))
n_baseline <- nrow(baseline)

cat("BASELINE SAMPLE (after post_detail filter):", n_baseline, "\n")
cat(paste(rep("-", 70), collapse=""), "\n\n")

# Check each variable individually
cat("TESTING EACH VARIABLE'S CONTRIBUTION TO OBSERVATION LOSS:\n\n")

# Test 1: real_pc_outlay
test1 <- baseline %>% filter(!is.na(real_pc_outlay))
cat("1. real_pc_outlay\n")
cat("   Missing:", n_baseline - nrow(test1), "obs\n")
cat("   N after filter:", nrow(test1), "\n\n")

# Test 2: real_pc_outlay > 0
test2 <- test1 %>% filter(real_pc_outlay > 0)
cat("2. real_pc_outlay > 0 (zeros)\n")
cat("   Zeros:", nrow(test1) - nrow(test2), "obs\n")
cat("   N after filter:", nrow(test2), "\n\n")

# Test 3: pop_30
test3 <- test2 %>% filter(!is.na(pop_30))
cat("3. pop_30\n")
cat("   Missing:", nrow(test2) - nrow(test3), "obs\n")
cat("   N after filter:", nrow(test3), "\n\n")

# Test 4: pop_20_30
test4 <- test3 %>% filter(!is.na(pop_20_30))
cat("4. pop_20_30\n")
cat("   Missing:", nrow(test3) - nrow(test4), "obs\n")
cat("   N after filter:", nrow(test4), "\n\n")

# Test 5: real_pc_rev_total_log
test5 <- test4 %>% filter(!is.na(real_pc_rev_total_log))
cat("5. real_pc_rev_total_log\n")
cat("   Missing:", nrow(test4) - nrow(test5), "obs\n")
cat("   N after filter:", nrow(test5), "\n\n")

# Test 6: L_real_pc_rev_total_log (LAGGED)
test6 <- test5 %>% filter(!is.na(L_real_pc_rev_total_log))
cat("6. L_real_pc_rev_total_log (LAGGED REVENUE)\n")
cat("   Missing:", nrow(test5) - nrow(test6), "obs\n")
cat("   N after filter:", nrow(test6), "\n\n")

# Test 7: region_
test7 <- test6 %>% filter(!is.na(region_))
cat("7. region_\n")
cat("   Missing:", nrow(test6) - nrow(test7), "obs\n")
cat("   N after filter:", nrow(test7), "\n\n")

# Test 8: leverage
test8 <- test7 %>% filter(!is.na(leverage))
cat("8. leverage (debt_to_rev29_lev_moody_std)\n")
cat("   Missing:", nrow(test7) - nrow(test8), "obs\n")
cat("   N after filter:", nrow(test8), "\n\n")

cat(paste(rep("=", 70), collapse=""), "\n")
cat("FINAL SAMPLE SIZE:", nrow(test8), "\n")
cat("EXPECTED (Stata):", 3829, "\n")
cat("DIFFERENCE:", nrow(test8) - 3829, "\n")
cat(paste(rep("=", 70), collapse=""), "\n\n")

# Summary table
cat("SUMMARY TABLE:\n")
summary_df <- data.frame(
  Variable = c(
    "Baseline (after post_detail)",
    "real_pc_outlay (not missing)",
    "real_pc_outlay > 0",
    "pop_30",
    "pop_20_30",
    "real_pc_rev_total_log",
    "L_real_pc_rev_total_log (LAG)",
    "region_",
    "leverage",
    "",
    "FINAL",
    "EXPECTED",
    "MISSING"
  ),
  N = c(
    n_baseline,
    nrow(test1),
    nrow(test2),
    nrow(test3),
    nrow(test4),
    nrow(test5),
    nrow(test6),
    nrow(test7),
    nrow(test8),
    NA,
    nrow(test8),
    3829,
    3829 - nrow(test8)
  ),
  Lost = c(
    0,
    n_baseline - nrow(test1),
    nrow(test1) - nrow(test2),
    nrow(test2) - nrow(test3),
    nrow(test3) - nrow(test4),
    nrow(test4) - nrow(test5),
    nrow(test5) - nrow(test6),
    nrow(test6) - nrow(test7),
    nrow(test7) - nrow(test8),
    NA, NA, NA, NA
  )
)

print(summary_df, row.names = FALSE)

cat("\n")
cat(paste(rep("=", 70), collapse=""), "\n")
cat("KEY FINDING: Which filter loses the most observations?\n")
cat(paste(rep("=", 70), collapse=""), "\n")

# Find the biggest loss
losses <- summary_df$Lost[!is.na(summary_df$Lost)]
vars <- summary_df$Variable[!is.na(summary_df$Lost)]
max_loss_idx <- which.max(losses)

cat("\nBIGGEST LOSS:", losses[max_loss_idx], "observations from", vars[max_loss_idx], "\n\n")

# Specific diagnosis
if (losses[max_loss_idx] >= 70) {
  cat("ACTION: This is likely the main culprit!\n")
  cat("Check: Does Stata handle this variable differently?\n")
  cat("Investigate: Are there implicit filters in the Stata code for this variable?\n")
} else {
  cat("NOTE: No single variable accounts for all 81 missing observations.\n")
  cat("The loss is distributed across multiple filters.\n")
  cat("This suggests slight differences in how R vs Stata handle missing values.\n")
}

cat("\n=== NEXT STEPS ===\n")
cat("1. Check if Stata's ppmlhdfe automatically drops more observations\n")
cat("2. Look for any sample restrictions in Stata code around line 434\n")
cat("3. Consider if 81 obs (2.1% of sample) is acceptable for replication\n")
cat("4. Compare coefficients - if they're very similar, N difference may not matter\n")
