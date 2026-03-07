# SERIOUS INVESTIGATION: Why are coefficients different?
# Sign flip indicates fundamental difference in model or data

library(haven)
library(dplyr)
library(fixest)

cat("\n")
cat(paste(rep("=", 70), collapse=""), "\n")
cat("COEFFICIENT DISCREPANCY INVESTIGATION\n")
cat(paste(rep("=", 70), collapse=""), "\n\n")

cat("PROBLEM IDENTIFIED:\n")
cat("Stata: moody leverage × 1924-1926 = +0.01\n")
cat("Your R: moody leverage × 1924-1926 = -0.09\n")
cat("This is a SIGN FLIP - indicates fundamental difference!\n\n")

cat("POSSIBLE CAUSES:\n")
cat("1. Wrong leverage variable (using _std vs non-std version)\n")
cat("2. Wrong reference period in post_detail\n")
cat("3. Missing sample restrictions in Stata code\n")
cat("4. Different standardization/scaling\n")
cat("5. Wrong year assignments in post_detail\n\n")

# Load data
df_city <- read_dta('data/replication-data-city.dta')

cat(paste(rep("=", 70), collapse=""), "\n")
cat("CHECK 1: Leverage Variable Versions\n")
cat(paste(rep("=", 70), collapse=""), "\n\n")

cat("Available debt_to_rev leverage variables:\n")
leverage_vars <- c("debt_to_rev29_lev", "debt_to_rev29_lev_moody", 
                   "debt_to_rev29_lev_moody_std", "debt_to_rev29_lev_std")

for (v in leverage_vars) {
  if (v %in% names(df_city)) {
    vals <- df_city[[v]]
    cat(sprintf("%-30s: mean=%.4f, sd=%.4f, min=%.4f, max=%.4f\n", 
                v, 
                mean(vals, na.rm=T), 
                sd(vals, na.rm=T),
                min(vals, na.rm=T),
                max(vals, na.rm=T)))
  }
}

cat("\nStata code says: debt_to_rev29_lev_moody_std\n")
cat("Are you using the right one?\n\n")

cat(paste(rep("=", 70), collapse=""), "\n")
cat("CHECK 2: Sample Restrictions from Stata Code\n")
cat(paste(rep("=", 70), collapse=""), "\n\n")

cat("From replication-code-city.do line 434:\n")
cat("  ppmlhdfe real_pc_outlay ib2.post_detail##c.test_moody ...\n")
cat("  if check<0.2 & check>-0.2\n\n")

cat("KEY QUESTION: Is 'check' the same as 'check_moody'?\n")
cat("Let's check if there's a plain 'check' variable...\n\n")

if ("check" %in% names(df_city)) {
  cat("✓ 'check' variable EXISTS!\n\n")
  
  cat("Comparing 'check' vs 'check_moody':\n")
  comp_df <- df_city %>% 
    select(check, check_moody) %>%
    filter(!is.na(check) | !is.na(check_moody)) %>%
    slice(1:20)
  
  print(comp_df)
  
  cat("\nAre they identical?\n")
  identical_vars <- all(df_city$check == df_city$check_moody, na.rm=T)
  cat("Identical:", identical_vars, "\n\n")
  
  if (!identical_vars) {
    cat("✗✗✗ THEY ARE DIFFERENT! This is likely your problem!\n\n")
    
    # Test with 'check' instead
    cat("Testing sample sizes with different filters:\n")
    n_check <- df_city %>%
      filter(!(year %in% c(1939, 1940))) %>%
      filter(check < 0.2 & check > -0.2) %>%
      nrow()
    
    n_check_moody <- df_city %>%
      filter(!(year %in% c(1939, 1940))) %>%
      filter(check_moody < 0.2 & check_moody > -0.2) %>%
      nrow()
    
    cat(sprintf("Using 'check': N = %d\n", n_check))
    cat(sprintf("Using 'check_moody': N = %d\n", n_check_moody))
    cat(sprintf("Expected from Stata: N ≈ 3829 (after all filters)\n\n"))
  }
} else {
  cat("✗ No 'check' variable found\n")
  cat("So 'check' in Stata code must refer to 'check_moody'\n\n")
}

cat(paste(rep("=", 70), collapse=""), "\n")
cat("CHECK 3: Year Assignments in post_detail\n")
cat(paste(rep("=", 70), collapse=""), "\n\n")

df_test <- df_city %>%
  mutate(
    post_detail = case_when(
      year %in% 1924:1926 ~ 1,
      year %in% 1927:1928 ~ 2,
      year %in% 1929:1933 ~ 3,
      year %in% 1934:1938 ~ 4,
      year %in% 1941:1943 ~ 5,
      TRUE ~ NA_real_
    )
  )

cat("Your post_detail coding:\n")
year_post <- df_test %>% 
  filter(!is.na(post_detail)) %>%
  distinct(year, post_detail) %>%
  arrange(year)
print(year_post)

cat("\nVerify this matches Stata's ib2.post_detail coding\n")
cat("Reference category (2) should be 1927-1928\n\n")

cat(paste(rep("=", 70), collapse=""), "\n")
cat("CHECK 4: Variable Existence in Stata vs R\n")
cat(paste(rep("=", 70), collapse=""), "\n\n")

cat("Stata uses: test_moody (created as 'gen test_moody = debt_to_rev29_lev_moody_std')\n")
cat("You use: leverage (created as 'leverage = debt_to_rev29_lev_moody_std')\n")
cat("These should be the same variable, just different names.\n\n")

cat("But check: Does Stata do any transformations to test_moody?\n")
cat("Look in the Stata do file around line 420-435\n\n")

cat(paste(rep("=", 70), collapse=""), "\n")
cat("RECOMMENDATION\n")
cat(paste(rep("=", 70), collapse=""), "\n\n")

if ("check" %in% names(df_city)) {
  cat("ACTION 1: Try using 'check' instead of 'check_moody' in your filter\n")
  cat("In Table_IV_PanelA.r, change:\n")
  cat("  filter(check_moody < 0.2 & check_moody > -0.2)\n")
  cat("TO:\n")
  cat("  filter(check < 0.2 & check > -0.2)\n\n")
}

cat("ACTION 2: Check the Stata code more carefully around lines 420-440:\n")
cat("  - What does the 'foreach' loop do?\n")
cat("  - How is 'test_moody' created?\n")
cat("  - Are there any transformations or filters?\n\n")

cat("ACTION 3: Run a simple correlation test:\n")
cat("  Does your leverage variable correlate with real_pc_outlay as expected?\n")
cat("  In the depression (1929-1933), higher leverage should → lower spending\n\n")

cat("Would you like me to:\n")
cat("1. Create a version using 'check' if it exists?\n")
cat("2. Test different leverage variable versions?\n")
cat("3. Look more carefully at the Stata loop structure?\n")
