# FINAL DIAGNOSIS: Why is the coefficient sign wrong?
# Test if it's a model specification issue

library(haven)
library(dplyr)
library(fixest)

df_city <- read_dta('data/replication-data-city.dta')

cat("\n=== TESTING MODEL SPECIFICATION ===\n\n")

# Prepare data exactly as in your script
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

df_model <- df %>%
  filter(!is.na(post_detail)) %>%
  filter(!is.na(real_pc_outlay), real_pc_outlay > 0) %>%
  filter(!is.na(pop_30), !is.na(pop_20_30)) %>%
  filter(!is.na(real_pc_rev_total_log), !is.na(L_real_pc_rev_total_log)) %>%
  filter(!is.na(region_), !is.na(leverage))

cat("Final sample N:", nrow(df_model), "\n\n")

# TEST 1: Simple correlation
cat("TEST 1: Simple correlations\n")
cat(paste(rep("-", 60), collapse=""), "\n\n")

# In 1929-1933 period, does higher leverage → lower outlay?
df_test_period <- df_model %>% filter(post_detail == 3)  # 1929-1933

cor_all <- cor(df_model$leverage, df_model$real_pc_outlay, use="complete.obs")
cor_depression <- cor(df_test_period$leverage, df_test_period$real_pc_outlay, use="complete.obs")

cat("Correlation(leverage, outlay) - ALL periods:", round(cor_all, 4), "\n")
cat("Correlation(leverage, outlay) - 1929-1933:", round(cor_depression, 4), "\n\n")

cat("EXPECTED: Negative correlation (higher debt → lower spending)\n")
if (cor_depression < 0) {
  cat("✓ Correlation is negative as expected\n\n")
} else {
  cat("✗ WARNING: Correlation is POSITIVE - this is unexpected!\n\n")
}

# TEST 2: Run YOUR current model
cat("TEST 2: Your current model (with full spec)\n")
cat(paste(rep("-", 60), collapse=""), "\n\n")

model_full <- fepois(
  real_pc_outlay ~ 
    i(post_detail, leverage, ref = 2) +
    i(year, ref = 1928) +
    i(year, pop_30) + 
    i(year, pop_20_30) +
    real_pc_rev_total_log + 
    L_real_pc_rev_total_log +
    i(year, region_) |
    id_ + year,
  data = df_model,
  cluster = ~ id_
)

coefs_full <- coef(model_full)
cat("Coefficient on leverage × 1924-1926:", 
    round(coefs_full["post_detail::1:leverage"], 4), "\n")
cat("Coefficient on leverage × 1929-1933:", 
    round(coefs_full["post_detail::3:leverage"], 4), "\n")
cat("Coefficient on leverage × 1934-1938:", 
    round(coefs_full["post_detail::4:leverage"], 4), "\n")
cat("Coefficient on leverage × 1941-1943:", 
    round(coefs_full["post_detail::5:leverage"], 4), "\n\n")

# TEST 3: Simplified model (just leverage interaction, no other controls)
cat("TEST 3: Simplified model (DiD only, no controls)\n")
cat(paste(rep("-", 60), collapse=""), "\n\n")

model_simple <- fepois(
  real_pc_outlay ~ 
    i(post_detail, leverage, ref = 2) |
    id_ + year,
  data = df_model,
  cluster = ~ id_
)

coefs_simple <- coef(model_simple)
cat("Coefficient on leverage × 1924-1926:", 
    round(coefs_simple["post_detail::1:leverage"], 4), "\n")
cat("Coefficient on leverage × 1929-1933:", 
    round(coefs_simple["post_detail::3:leverage"], 4), "\n")
cat("Coefficient on leverage × 1934-1938:", 
    round(coefs_simple["post_detail::4:leverage"], 4), "\n")
cat("Coefficient on leverage × 1941-1943:", 
    round(coefs_simple["post_detail::5:leverage"], 4), "\n\n")

# TEST 4: Check if year reference is the problem
cat("TEST 4: Without explicit year reference\n")
cat(paste(rep("-", 60), collapse=""), "\n\n")

model_no_year_ref <- fepois(
  real_pc_outlay ~ 
    i(post_detail, leverage, ref = 2) +
    i(year, pop_30) + 
    i(year, pop_20_30) +
    real_pc_rev_total_log + 
    L_real_pc_rev_total_log +
    i(year, region_) |
    id_ + year,
  data = df_model,
  cluster = ~ id_
)

coefs_noyref <- coef(model_no_year_ref)
cat("Coefficient on leverage × 1924-1926:", 
    round(coefs_noyref["post_detail::1:leverage"], 4), "\n")
cat("Coefficient on leverage × 1929-1933:", 
    round(coefs_noyref["post_detail::3:leverage"], 4), "\n\n")

cat("=== COMPARISON ===\n\n")
cat("                        1924-1926    1929-1933    1934-1938    1941-1943\n")
cat("Full model:           ",
    sprintf("%10.4f", coefs_full["post_detail::1:leverage"]),
    sprintf("%12.4f", coefs_full["post_detail::3:leverage"]),
    sprintf("%12.4f", coefs_full["post_detail::4:leverage"]),
    sprintf("%12.4f", coefs_full["post_detail::5:leverage"]), "\n")
cat("Simple model:         ",
    sprintf("%10.4f", coefs_simple["post_detail::1:leverage"]),
    sprintf("%12.4f", coefs_simple["post_detail::3:leverage"]),
    sprintf("%12.4f", coefs_simple["post_detail::4:leverage"]),
    sprintf("%12.4f", coefs_simple["post_detail::5:leverage"]), "\n")
cat("Expected (Stata):      0.0100      -0.2670      -0.3295      -0.2026\n\n")

cat("=== DIAGNOSIS ===\n\n")

# Check if simple vs full flips the sign
sign_flip <- sign(coefs_simple["post_detail::1:leverage"]) != sign(coefs_full["post_detail::1:leverage"])

if (sign_flip) {
  cat("✗ CRITICAL: Sign flips between simple and full model!\n")
  cat("  This means one of your control variables is causing the issue.\n")
  cat("  Most likely: i(year, ref=1928) or the revenue controls.\n\n")
} else {
  cat("Sign is consistent across models.\n")
  cat("The problem is in the base model specification itself.\n\n")
}

# Additional check: Is the leverage variable scaled correctly?
cat("=== LEVERAGE VARIABLE CHECK ===\n\n")
cat("debt_to_rev29_lev_moody_std summary:\n")
summary(df_model$leverage)

cat("\nExpected: Mean ≈ 0, SD ≈ 1 (standardized variable)\n")
if (abs(mean(df_model$leverage, na.rm=TRUE)) < 0.1 && 
    abs(sd(df_model$leverage, na.rm=TRUE) - 1) < 0.1) {
  cat("✓ Variable appears properly standardized\n\n")
} else {
  cat("✗ WARNING: Variable scaling might be off!\n\n")
}

cat("=== RECOMMENDATION ===\n\n")
cat("Based on diagnostics:\n")
cat("1. If simple model matches Stata but full doesn't → Control variable issue\n")
cat("2. If both models are wrong → Check leverage variable or period coding\n")
cat("3. Compare correlation patterns - do they make economic sense?\n\n")

cat("Next step: Show me your output and I'll pinpoint the exact issue.\n")
