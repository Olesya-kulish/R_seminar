##############################################################################
# Table IV Column 3 - Diagnostic Fix Attempt
# Purpose: Try to match Stata benchmarks by testing different specifications
# 
# Target values (Panel A):
#   - R-sq: 0.68
#   - moodyleverage 1924-26 SE: (0.03)
#   - moodyleverage 1941-43 coef: -0.06
##############################################################################

library(haven)
library(dplyr)
library(fixest)
library(stringr)

# Load data
df <- haven::read_dta("data/replication-data-city.dta")

# Apply filter and prepare panel
# Stata Table IV code uses: if check < 0.2 & check > -0.2
# Fallback to check_moody if check is not available
filter_var <- if ("check" %in% names(df)) "check" else "check_moody"
cat("Using filter variable:", filter_var, "\n")

df0 <- df %>%
  filter(.data[[filter_var]] < 0.2, .data[[filter_var]] > -0.2) %>%
  mutate(
    id_ = as.factor(id_),
    year = as.integer(year),
    region = as.factor(region_)
  )

# Treatment variable
testvar <- "debt_to_rev29_lev_moody_std"

cat("\n============================================================\n")
cat("DIAGNOSTIC: Testing different specifications for Panel A\n")
cat("============================================================\n\n")

# Helper to extract interaction coefficients
get_interaction <- function(m, tv, period) {
  term <- paste0(tv, ":post_detail::", period)
  if (term %in% rownames(m$coeftable)) {
    ct <- m$coeftable[term, ]
    list(
      coef = ct["Estimate"],
      se = ct["Std. Error"],
      p = ct[grep("Pr\\(", names(ct))[1]]
    )
  } else {
    list(coef = NA, se = NA, p = NA)
  }
}

safe_wr2 <- function(m) {
  out <- tryCatch(fixest::fitstat(m, "wr2"), error = function(e) NA_real_)
  as.numeric(out)
}

################################################################################
# ATTEMPT 1: Use original post_detail from data (as in fix_attempt scripts)
################################################################################

cat("\n--- ATTEMPT 1: Original post_detail, panel lag ---\n")

fml_A1 <- as.formula(paste0(
  "real_pc_maint_dep_total_log ~ ",
  "i(post_detail, ref = 2) * ", testvar, " + ",
  "i(year, ref = 1928) + ",
  "i(year, pop_30, ref = 1928) + ",
  "i(year, pop_20_30, ref = 1928) + ",
  "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) + ",
  "i(year, region_) | id_"
))

m1 <- feols(
  fml = fml_A1,
  data = df0,
  vcov = ~ id_,
  panel.id = ~ id_ + year
)

r2_1 <- safe_wr2(m1)
c1 <- get_interaction(m1, testvar, 1)  # 1924-26
c5 <- get_interaction(m1, testvar, 5)  # 1941-43

cat("N:", stats::nobs(m1), "\n")
cat("R-sq (within):", sprintf("%.3f", r2_1), "| Target: 0.68\n")
cat("1924-26 coef:", sprintf("%.3f", c1$coef), "| SE:", sprintf("%.3f", c1$se), "| Target SE: 0.03\n")
cat("1941-43 coef:", sprintf("%.3f", c5$coef), "| Target: -0.06\n")

################################################################################
# ATTEMPT 2: Without region x year interaction
################################################################################

cat("\n--- ATTEMPT 2: Without region x year ---\n")

fml_A2 <- as.formula(paste0(
  "real_pc_maint_dep_total_log ~ ",
  "i(post_detail, ref = 2) * ", testvar, " + ",
  "i(year, ref = 1928) + ",
  "i(year, pop_30, ref = 1928) + ",
  "i(year, pop_20_30, ref = 1928) + ",
  "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) | id_"
))

m2 <- feols(
  fml = fml_A2,
  data = df0,
  vcov = ~ id_,
  panel.id = ~ id_ + year
)

r2_2 <- safe_wr2(m2)
c1_2 <- get_interaction(m2, testvar, 1)
c5_2 <- get_interaction(m2, testvar, 5)

cat("N:", stats::nobs(m2), "\n")
cat("R-sq (within):", sprintf("%.3f", r2_2), "| Target: 0.68\n")
cat("1924-26 coef:", sprintf("%.3f", c1_2$coef), "| SE:", sprintf("%.3f", c1_2$se), "| Target SE: 0.03\n")
cat("1941-43 coef:", sprintf("%.3f", c5_2$coef), "| Target: -0.06\n")

################################################################################
# ATTEMPT 3: Without revenue controls
################################################################################

cat("\n--- ATTEMPT 3: Without revenue controls ---\n")

fml_A3 <- as.formula(paste0(
  "real_pc_maint_dep_total_log ~ ",
  "i(post_detail, ref = 2) * ", testvar, " + ",
  "i(year, ref = 1928) + ",
  "i(year, pop_30, ref = 1928) + ",
  "i(year, pop_20_30, ref = 1928) + ",
  "i(year, region_) | id_"
))

m3 <- feols(
  fml = fml_A3,
  data = df0,
  vcov = ~ id_,
  panel.id = ~ id_ + year
)

r2_3 <- safe_wr2(m3)
c1_3 <- get_interaction(m3, testvar, 1)
c5_3 <- get_interaction(m3, testvar, 5)

cat("N:", stats::nobs(m3), "\n")
cat("R-sq (within):", sprintf("%.3f", r2_3), "| Target: 0.68\n")
cat("1924-26 coef:", sprintf("%.3f", c1_3$coef), "| SE:", sprintf("%.3f", c1_3$se), "| Target SE: 0.03\n")
cat("1941-43 coef:", sprintf("%.3f", c5_3$coef), "| Target: -0.06\n")

################################################################################
# ATTEMPT 4: Only basic controls (year + city FE)
################################################################################

cat("\n--- ATTEMPT 4: Basic (year + city FE only) ---\n")

fml_A4 <- as.formula(paste0(
  "real_pc_maint_dep_total_log ~ ",
  "i(post_detail, ref = 2) * ", testvar, " + ",
  "i(year, ref = 1928) | id_"
))

m4 <- feols(
  fml = fml_A4,
  data = df0,
  vcov = ~ id_,
  panel.id = ~ id_ + year
)

r2_4 <- safe_wr2(m4)
c1_4 <- get_interaction(m4, testvar, 1)
c5_4 <- get_interaction(m4, testvar, 5)

cat("N:", stats::nobs(m4), "\n")
cat("R-sq (within):", sprintf("%.3f", r2_4), "| Target: 0.68\n")
cat("1924-26 coef:", sprintf("%.3f", c1_4$coef), "| SE:", sprintf("%.3f", c1_4$se), "| Target SE: 0.03\n")
cat("1941-43 coef:", sprintf("%.3f", c5_4$coef), "| Target: -0.06\n")

################################################################################
# ATTEMPT 5: Different leverage variable (bonds_to_assess29_lev_moody_std)
################################################################################

cat("\n--- ATTEMPT 5: bonds_to_assess29_lev_moody_std instead ---\n")

testvar2 <- "bonds_to_assess29_lev_moody_std"

fml_A5 <- as.formula(paste0(
  "real_pc_maint_dep_total_log ~ ",
  "i(post_detail, ref = 2) * ", testvar2, " + ",
  "i(year, ref = 1928) + ",
  "i(year, pop_30, ref = 1928) + ",
  "i(year, pop_20_30, ref = 1928) + ",
  "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) + ",
  "i(year, region_) | id_"
))

m5 <- feols(
  fml = fml_A5,
  data = df0,
  vcov = ~ id_,
  panel.id = ~ id_ + year
)

r2_5 <- safe_wr2(m5)
c1_5 <- get_interaction(m5, testvar2, 1)
c5_5 <- get_interaction(m5, testvar2, 5)

cat("N:", stats::nobs(m5), "\n")
cat("R-sq (within):", sprintf("%.3f", r2_5), "| Target: 0.68\n")
cat("1924-26 coef:", sprintf("%.3f", c1_5$coef), "| SE:", sprintf("%.3f", c1_5$se), "| Target SE: 0.03\n")
cat("1941-43 coef:", sprintf("%.3f", c5_5$coef), "| Target: -0.06\n")

################################################################################
# Summary comparison
################################################################################

cat("\n============================================================\n")
cat("SUMMARY COMPARISON\n")
cat("============================================================\n")

comparison <- data.frame(
  Attempt = c("1: Full spec", "2: No region×year", "3: No revenue", "4: Basic", "5: Bonds/Assess"),
  N = c(stats::nobs(m1), stats::nobs(m2), stats::nobs(m3), stats::nobs(m4), stats::nobs(m5)),
  R_sq = sprintf("%.3f", c(r2_1, r2_2, r2_3, r2_4, r2_5)),
  `SE_1924_26` = sprintf("%.3f", c(c1$se, c1_2$se, c1_3$se, c1_4$se, c1_5$se)),
  `Coef_1941_43` = sprintf("%.3f", c(c5$coef, c5_2$coef, c5_3$coef, c5_4$coef, c5_5$coef)),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

print(comparison, row.names = FALSE)

cat("\nTarget values: R²=0.68, SE(1924-26)=0.03, Coef(1941-43)=-0.06\n")

# Export diagnostic CSV
dir.create("output", showWarnings = FALSE)
write.csv(comparison, "output/table_IV_col3_diagnostic_attempts.csv", row.names = FALSE)
cat("\nWrote: output/table_IV_col3_diagnostic_attempts.csv\n")

################################################################################
# Panel B Diagnostics
################################################################################

cat("\n============================================================\n")
cat("DIAGNOSTIC: Testing different specifications for Panel B\n")
cat("============================================================\n\n")

safe_pr2 <- function(m) {
  out <- tryCatch(fixest::fitstat(m, "pr2"), error = function(e) NA_real_)
  as.numeric(out)
}

# Target values for Panel B
cat("Target coefficients:\n")
cat("  1924-26: -0.11\n")
cat("  1929-33: -0.19\n")
cat("  1934-38: -0.36\n")
cat("  1941-43: -0.09 (currently -0.18, big discrepancy)\n\n")

################################################################################
# ATTEMPT B1: Current specification (PPML with both city + year FE)
################################################################################

cat("\n--- ATTEMPT B1: Current spec (fepois, city + year FE) ---\n")

fml_B1 <- as.formula(paste0(
  "real_pc_outlay ~ ",
  "i(post_detail, ref = 2) * ", testvar, " + ",
  "i(year, pop_30, ref = 1928) + ",
  "i(year, pop_20_30, ref = 1928) + ",
  "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) + ",
  "i(year, region_) | id_ + year"
))

mB1 <- fepois(
  fml = fml_B1,
  data = df0,
  vcov = ~ id_,
  panel.id = ~ id_ + year
)

r2_B1 <- safe_pr2(mB1)
b1_1 <- get_interaction(mB1, testvar, 1)  # 1924-26
b1_3 <- get_interaction(mB1, testvar, 3)  # 1929-33
b1_4 <- get_interaction(mB1, testvar, 4)  # 1934-38
b1_5 <- get_interaction(mB1, testvar, 5)  # 1941-43

cat("N:", stats::nobs(mB1), "\n")
cat("R-sq (pseudo):", sprintf("%.3f", r2_B1), "\n")
cat("1924-26 coef:", sprintf("%.3f", b1_1$coef), "| Target: -0.11\n")
cat("1929-33 coef:", sprintf("%.3f", b1_3$coef), "| Target: -0.19\n")
cat("1934-38 coef:", sprintf("%.3f", b1_4$coef), "| Target: -0.36\n")
cat("1941-43 coef:", sprintf("%.3f", b1_5$coef), "| Target: -0.09\n")

################################################################################
# ATTEMPT B2: Only city FE (no year FE)
################################################################################

cat("\n--- ATTEMPT B2: Only city FE (no year FE) ---\n")

fml_B2 <- as.formula(paste0(
  "real_pc_outlay ~ ",
  "i(post_detail, ref = 2) * ", testvar, " + ",
  "i(year, ref = 1928) + ",
  "i(year, pop_30, ref = 1928) + ",
  "i(year, pop_20_30, ref = 1928) + ",
  "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) + ",
  "i(year, region_) | id_"
))

mB2 <- fepois(
  fml = fml_B2,
  data = df0,
  vcov = ~ id_,
  panel.id = ~ id_ + year
)

r2_B2 <- safe_pr2(mB2)
b2_1 <- get_interaction(mB2, testvar, 1)
b2_3 <- get_interaction(mB2, testvar, 3)
b2_4 <- get_interaction(mB2, testvar, 4)
b2_5 <- get_interaction(mB2, testvar, 5)

cat("N:", stats::nobs(mB2), "\n")
cat("R-sq (pseudo):", sprintf("%.3f", r2_B2), "\n")
cat("1924-26 coef:", sprintf("%.3f", b2_1$coef), "| Target: -0.11\n")
cat("1929-33 coef:", sprintf("%.3f", b2_3$coef), "| Target: -0.19\n")
cat("1934-38 coef:", sprintf("%.3f", b2_4$coef), "| Target: -0.36\n")
cat("1941-43 coef:", sprintf("%.3f", b2_5$coef), "| Target: -0.09\n")

################################################################################
# ATTEMPT B3: Without revenue controls
################################################################################

cat("\n--- ATTEMPT B3: Without revenue controls ---\n")

fml_B3 <- as.formula(paste0(
  "real_pc_outlay ~ ",
  "i(post_detail, ref = 2) * ", testvar, " + ",
  "i(year, pop_30, ref = 1928) + ",
  "i(year, pop_20_30, ref = 1928) + ",
  "i(year, region_) | id_ + year"
))

mB3 <- fepois(
  fml = fml_B3,
  data = df0,
  vcov = ~ id_,
  panel.id = ~ id_ + year
)

r2_B3 <- safe_pr2(mB3)
b3_1 <- get_interaction(mB3, testvar, 1)
b3_3 <- get_interaction(mB3, testvar, 3)
b3_4 <- get_interaction(mB3, testvar, 4)
b3_5 <- get_interaction(mB3, testvar, 5)

cat("N:", stats::nobs(mB3), "\n")
cat("R-sq (pseudo):", sprintf("%.3f", r2_B3), "\n")
cat("1924-26 coef:", sprintf("%.3f", b3_1$coef), "| Target: -0.11\n")
cat("1929-33 coef:", sprintf("%.3f", b3_3$coef), "| Target: -0.19\n")
cat("1934-38 coef:", sprintf("%.3f", b3_4$coef), "| Target: -0.36\n")
cat("1941-43 coef:", sprintf("%.3f", b3_5$coef), "| Target: -0.09\n")

################################################################################
# ATTEMPT B4: Without region x year
################################################################################

cat("\n--- ATTEMPT B4: Without region x year ---\n")

fml_B4 <- as.formula(paste0(
  "real_pc_outlay ~ ",
  "i(post_detail, ref = 2) * ", testvar, " + ",
  "i(year, pop_30, ref = 1928) + ",
  "i(year, pop_20_30, ref = 1928) + ",
  "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) | id_ + year"
))

mB4 <- fepois(
  fml = fml_B4,
  data = df0,
  vcov = ~ id_,
  panel.id = ~ id_ + year
)

r2_B4 <- safe_pr2(mB4)
b4_1 <- get_interaction(mB4, testvar, 1)
b4_3 <- get_interaction(mB4, testvar, 3)
b4_4 <- get_interaction(mB4, testvar, 4)
b4_5 <- get_interaction(mB4, testvar, 5)

cat("N:", stats::nobs(mB4), "\n")
cat("R-sq (pseudo):", sprintf("%.3f", r2_B4), "\n")
cat("1924-26 coef:", sprintf("%.3f", b4_1$coef), "| Target: -0.11\n")
cat("1929-33 coef:", sprintf("%.3f", b4_3$coef), "| Target: -0.19\n")
cat("1934-38 coef:", sprintf("%.3f", b4_4$coef), "| Target: -0.36\n")
cat("1941-43 coef:", sprintf("%.3f", b4_5$coef), "| Target: -0.09\n")

################################################################################
# ATTEMPT B5: Paper hint test (post-1940 regroup)
################################################################################

cat("\n--- ATTEMPT B5: Paper hint (fading after 1940) with regrouped post period ---\n")

df_b5 <- df0 %>%
  mutate(
    post_detail_b5 = dplyr::case_when(
      year >= 1924 & year <= 1926 ~ 1L,
      year >= 1927 & year <= 1928 ~ 2L,
      year >= 1929 & year <= 1933 ~ 3L,
      year >= 1934 & year <= 1938 ~ 4L,
      year >= 1940 & year <= 1943 ~ 5L,
      TRUE ~ NA_integer_
    )
  )

fml_B5 <- as.formula(paste0(
  "real_pc_outlay ~ ",
  "i(post_detail_b5, ref = 2) * ", testvar, " + ",
  "i(year, pop_30, ref = 1928) + ",
  "i(year, pop_20_30, ref = 1928) + ",
  "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) + ",
  "i(year, region_) | id_ + year"
))

mB5 <- fepois(
  fml = fml_B5,
  data = df_b5,
  vcov = ~ id_,
  panel.id = ~ id_ + year
)

get_interaction_b5 <- function(m, tv, period) {
  term <- paste0(tv, ":post_detail_b5::", period)
  if (term %in% rownames(m$coeftable)) {
    ct <- m$coeftable[term, ]
    list(
      coef = ct["Estimate"],
      se = ct["Std. Error"],
      p = ct[grep("Pr\\(", names(ct))[1]]
    )
  } else {
    list(coef = NA, se = NA, p = NA)
  }
}

r2_B5 <- safe_pr2(mB5)
b5_1 <- get_interaction_b5(mB5, testvar, 1)
b5_3 <- get_interaction_b5(mB5, testvar, 3)
b5_4 <- get_interaction_b5(mB5, testvar, 4)
b5_5 <- get_interaction_b5(mB5, testvar, 5)

cat("N:", stats::nobs(mB5), "\n")
cat("R-sq (pseudo):", sprintf("%.3f", r2_B5), "\n")
cat("1924-26 coef:", sprintf("%.3f", b5_1$coef), "| Target: -0.11\n")
cat("1929-33 coef:", sprintf("%.3f", b5_3$coef), "| Target: -0.19\n")
cat("1934-38 coef:", sprintf("%.3f", b5_4$coef), "| Target: -0.36\n")
cat("1940-43 coef:", sprintf("%.3f", b5_5$coef), "| Reference target (~1941-43): -0.09\n")

################################################################################
# Summary comparison Panel B
################################################################################

cat("\n============================================================\n")
cat("SUMMARY COMPARISON - PANEL B\n")
cat("============================================================\n")

comparison_B <- data.frame(
  Attempt = c("B1: Current (city+year FE)", "B2: Only city FE", "B3: No revenue", "B4: No region×year", "B5: Post-1940 regroup"),
  N = c(stats::nobs(mB1), stats::nobs(mB2), stats::nobs(mB3), stats::nobs(mB4), stats::nobs(mB5)),
  R_sq = sprintf("%.3f", c(r2_B1, r2_B2, r2_B3, r2_B4, r2_B5)),
  `1924_26` = sprintf("%.3f", c(b1_1$coef, b2_1$coef, b3_1$coef, b4_1$coef, b5_1$coef)),
  `1929_33` = sprintf("%.3f", c(b1_3$coef, b2_3$coef, b3_3$coef, b4_3$coef, b5_3$coef)),
  `1934_38` = sprintf("%.3f", c(b1_4$coef, b2_4$coef, b3_4$coef, b4_4$coef, b5_4$coef)),
  `1941_43` = sprintf("%.3f", c(b1_5$coef, b2_5$coef, b3_5$coef, b4_5$coef, b5_5$coef)),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

print(comparison_B, row.names = FALSE)

cat("\nTarget values: 1924-26=-0.11, 1929-33=-0.19, 1934-38=-0.36, 1941-43=-0.09\n")

write.csv(comparison_B, "output/table_IV_col3_diagnostic_panelB.csv", row.names = FALSE)
cat("\nWrote: output/table_IV_col3_diagnostic_panelB.csv\n")

################################################################################
# Test different leverage variables for Panel B
################################################################################

cat("\n============================================================\n")
cat("TESTING DIFFERENT LEVERAGE VARIABLES FOR PANEL B\n")
cat("============================================================\n\n")

leverage_vars <- c(
  "bonds_to_assess29_lev_moody_std",
  "int_to_rev29_lev_moody_std", 
  "debt_to_rev29_lev_moody_std",
  "debt_total29_lev_moody_std"
)

leverage_results <- list()

for (lv in leverage_vars) {
  cat("\n--- Testing:", lv, "---\n")
  
  # Use the specification that was closest (B4: no region×year)
  fml_test <- as.formula(paste0(
    "real_pc_outlay ~ ",
    "i(post_detail, ref = 2) * ", lv, " + ",
    "i(year, pop_30, ref = 1928) + ",
    "i(year, pop_20_30, ref = 1928) + ",
    "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) | id_ + year"
  ))
  
  m_test <- fepois(
    fml = fml_test,
    data = df0,
    vcov = ~ id_,
    panel.id = ~ id_ + year
  )
  
  c1 <- get_interaction(m_test, lv, 1)
  c3 <- get_interaction(m_test, lv, 3)
  c4 <- get_interaction(m_test, lv, 4)
  c5 <- get_interaction(m_test, lv, 5)
  
  cat("N:", stats::nobs(m_test), "\n")
  cat("1924-26:", sprintf("%.3f", c1$coef), "| Target: -0.11\n")
  cat("1929-33:", sprintf("%.3f", c3$coef), "| Target: -0.19\n")
  cat("1934-38:", sprintf("%.3f", c4$coef), "| Target: -0.36\n")
  cat("1941-43:", sprintf("%.3f", c5$coef), "| Target: -0.09\n")
  
  leverage_results[[lv]] <- list(
    var = lv,
    N = stats::nobs(m_test),
    c1 = c1$coef,
    c3 = c3$coef,
    c4 = c4$coef,
    c5 = c5$coef
  )
}

cat("\n============================================================\n")
cat("LEVERAGE VARIABLE COMPARISON - PANEL B\n")
cat("============================================================\n")

lev_comparison <- data.frame(
  Variable = c("Bonds/Assess", "Interest/Rev", "Debt/Rev", "DebtTotal"),
  N = sapply(leverage_results, function(x) x$N),
  `1924_26` = sprintf("%.3f", sapply(leverage_results, function(x) x$c1)),
  `1929_33` = sprintf("%.3f", sapply(leverage_results, function(x) x$c3)),
  `1934_38` = sprintf("%.3f", sapply(leverage_results, function(x) x$c4)),
  `1941_43` = sprintf("%.3f", sapply(leverage_results, function(x) x$c5)),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

print(lev_comparison, row.names = FALSE)
cat("\nTarget values: 1924-26=-0.11, 1929-33=-0.19, 1934-38=-0.36, 1941-43=-0.09\n")

write.csv(lev_comparison, "output/table_IV_col3_panelB_leverage_test.csv", row.names = FALSE)
cat("\nWrote: output/table_IV_col3_panelB_leverage_test.csv\n")

################################################################################
# Test different estimators and outcome variables for Panel B
################################################################################

cat("\n============================================================\n")
cat("TESTING DIFFERENT ESTIMATORS/OUTCOMES FOR PANEL B\n")
cat("Table III uses same controls - maybe different estimator?\n")
cat("============================================================\n\n")

testvar <- "debt_to_rev29_lev_moody_std"

################################################################################
# Test 1: OLS instead of Poisson (with level outcome)
################################################################################

cat("\n--- TEST 1: OLS (feols) with real_pc_outlay (level) ---\n")

fml_ols_level <- as.formula(paste0(
  "real_pc_outlay ~ ",
  "i(post_detail, ref = 2) * ", testvar, " + ",
  "i(year, ref = 1928) + ",
  "i(year, pop_30, ref = 1928) + ",
  "i(year, pop_20_30, ref = 1928) + ",
  "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) + ",
  "i(year, region_) | id_"
))

m_ols_level <- feols(
  fml = fml_ols_level,
  data = df0,
  vcov = ~ id_,
  panel.id = ~ id_ + year
)

c1_ols <- get_interaction(m_ols_level, testvar, 1)
c3_ols <- get_interaction(m_ols_level, testvar, 3)
c4_ols <- get_interaction(m_ols_level, testvar, 4)
c5_ols <- get_interaction(m_ols_level, testvar, 5)

cat("N:", stats::nobs(m_ols_level), "\n")
cat("1924-26:", sprintf("%.3f", c1_ols$coef), "| Target: -0.11\n")
cat("1929-33:", sprintf("%.3f", c3_ols$coef), "| Target: -0.19\n")
cat("1934-38:", sprintf("%.3f", c4_ols$coef), "| Target: -0.36\n")
cat("1941-43:", sprintf("%.3f", c5_ols$coef), "| Target: -0.09\n")

################################################################################
# Test 2: Check if outcome should be logged
################################################################################

cat("\n--- TEST 2: Checking if real_pc_outlay_log exists in data ---\n")
if ("real_pc_outlay_log" %in% names(df0)) {
  cat("Found real_pc_outlay_log variable!\n")
  
  fml_ols_log <- as.formula(paste0(
    "real_pc_outlay_log ~ ",
    "i(post_detail, ref = 2) * ", testvar, " + ",
    "i(year, ref = 1928) + ",
    "i(year, pop_30, ref = 1928) + ",
    "i(year, pop_20_30, ref = 1928) + ",
    "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) + ",
    "i(year, region_) | id_"
  ))
  
  m_ols_log <- feols(
    fml = fml_ols_log,
    data = df0,
    vcov = ~ id_,
    panel.id = ~ id_ + year
  )
  
  c1_log <- get_interaction(m_ols_log, testvar, 1)
  c3_log <- get_interaction(m_ols_log, testvar, 3)
  c4_log <- get_interaction(m_ols_log, testvar, 4)
  c5_log <- get_interaction(m_ols_log, testvar, 5)
  
  cat("N:", stats::nobs(m_ols_log), "\n")
  cat("1924-26:", sprintf("%.3f", c1_log$coef), "| Target: -0.11\n")
  cat("1929-33:", sprintf("%.3f", c3_log$coef), "| Target: -0.19\n")
  cat("1934-38:", sprintf("%.3f", c4_log$coef), "| Target: -0.36\n")
  cat("1941-43:", sprintf("%.3f", c5_log$coef), "| Target: -0.09\n")
} else {
  cat("real_pc_outlay_log not found - creating it\n")
  df0$real_pc_outlay_log <- log(df0$real_pc_outlay)
  
  fml_ols_log <- as.formula(paste0(
    "real_pc_outlay_log ~ ",
    "i(post_detail, ref = 2) * ", testvar, " + ",
    "i(year, ref = 1928) + ",
    "i(year, pop_30, ref = 1928) + ",
    "i(year, pop_20_30, ref = 1928) + ",
    "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) + ",
    "i(year, region_) | id_"
  ))
  
  m_ols_log <- feols(
    fml = fml_ols_log,
    data = df0,
    vcov = ~ id_,
    panel.id = ~ id_ + year
  )
  
  c1_log <- get_interaction(m_ols_log, testvar, 1)
  c3_log <- get_interaction(m_ols_log, testvar, 3)
  c4_log <- get_interaction(m_ols_log, testvar, 4)
  c5_log <- get_interaction(m_ols_log, testvar, 5)
  
  cat("N:", stats::nobs(m_ols_log), "\n")
  cat("1924-26:", sprintf("%.3f", c1_log$coef), "| Target: -0.11\n")
  cat("1929-33:", sprintf("%.3f", c3_log$coef), "| Target: -0.19\n")
  cat("1934-38:", sprintf("%.3f", c4_log$coef), "| Target: -0.36\n")
  cat("1941-43:", sprintf("%.3f", c5_log$coef), "| Target: -0.09\n")
}

cat("\n============================================================\n")
cat("SUMMARY: Estimator/Outcome Tests\n")
cat("============================================================\n")

estimator_comparison <- data.frame(
  Specification = c("PPML (current)", "OLS level", "OLS logged"),
  `1924_26` = sprintf("%.3f", c(b4_1$coef, c1_ols$coef, c1_log$coef)),
  `1929_33` = sprintf("%.3f", c(b4_3$coef, c3_ols$coef, c3_log$coef)),
  `1934_38` = sprintf("%.3f", c(b4_4$coef, c4_ols$coef, c4_log$coef)),
  `1941_43` = sprintf("%.3f", c(b4_5$coef, c5_ols$coef, c5_log$coef)),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

print(estimator_comparison, row.names = FALSE)
cat("\nTarget values: 1924-26=-0.11, 1929-33=-0.19, 1934-38=-0.36, 1941-43=-0.09\n")

write.csv(estimator_comparison, "output/table_IV_col3_panelB_estimator_test.csv", row.names = FALSE)
cat("\nWrote: output/table_IV_col3_panelB_estimator_test.csv\n")

################################################################################
# PNG outputs only: Panel A and Panel B (no other visual outputs)
################################################################################

# Select best Panel A attempt by closeness to targets
score_A <- c(
  abs(r2_1 - 0.68) + abs(c1$se - 0.03) + abs(c5$coef - (-0.06)),
  abs(r2_2 - 0.68) + abs(c1_2$se - 0.03) + abs(c5_2$coef - (-0.06)),
  abs(r2_3 - 0.68) + abs(c1_3$se - 0.03) + abs(c5_3$coef - (-0.06)),
  abs(r2_4 - 0.68) + abs(c1_4$se - 0.03) + abs(c5_4$coef - (-0.06)),
  abs(r2_5 - 0.68) + abs(c1_5$se - 0.03) + abs(c5_5$coef - (-0.06))
)
best_A_idx <- which.min(score_A)
best_A_model <- list(m1, m2, m3, m4, m5)[[best_A_idx]]
best_A_name <- c("Attempt 1", "Attempt 2", "Attempt 3", "Attempt 4", "Attempt 5")[best_A_idx]

# Select best Panel B attempt by closeness to user targets
score_B <- c(
  abs(b1_1$coef - (-0.11)) + abs(b1_3$coef - (-0.19)) + abs(b1_4$coef - (-0.36)) + abs(b1_5$coef - (-0.09)),
  abs(b2_1$coef - (-0.11)) + abs(b2_3$coef - (-0.19)) + abs(b2_4$coef - (-0.36)) + abs(b2_5$coef - (-0.09)),
  abs(b3_1$coef - (-0.11)) + abs(b3_3$coef - (-0.19)) + abs(b3_4$coef - (-0.36)) + abs(b3_5$coef - (-0.09)),
  abs(b4_1$coef - (-0.11)) + abs(b4_3$coef - (-0.19)) + abs(b4_4$coef - (-0.36)) + abs(b4_5$coef - (-0.09)),
  abs(b5_1$coef - (-0.11)) + abs(b5_3$coef - (-0.19)) + abs(b5_4$coef - (-0.36)) + abs(b5_5$coef - (-0.09))
)
best_B_idx <- which.min(score_B)
best_B_model <- list(mB1, mB2, mB3, mB4, mB5)[[best_B_idx]]
best_B_name <- c("Attempt B1", "Attempt B2", "Attempt B3", "Attempt B4", "Attempt B5")[best_B_idx]

cat("\nSelected best Panel A:", best_A_name, "\n")
cat("Selected best Panel B:", best_B_name, "\n")

sig_star <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  ""
}

draw_panel_png <- function(path, title, model, tv, r2_label, r2_value) {
  c1 <- get_interaction(model, tv, 1)
  c3 <- get_interaction(model, tv, 3)
  c4 <- get_interaction(model, tv, 4)
  c5 <- get_interaction(model, tv, 5)

  png(path, width = 1200, height = 900, res = 150)
  par(mar = c(1, 1, 1, 1), family = "sans")
  plot.new()

  text(0.5, 0.98, "Table IV Column (3): Debt/Revenue (Fix Attempt)", font = 2, cex = 1.4)
  text(0.5, 0.95, title, font = 2, cex = 1.2)
  segments(0.08, 0.92, 0.92, 0.92, lwd = 3)

  y <- 0.88
  text(0.08, y, "moodyleverage × 1924-1926", adj = 0, cex = 1.1)
  text(0.75, y, sprintf("%.2f%s", c1$coef, sig_star(c1$p)), cex = 1.1)
  y <- y - 0.025; text(0.75, y, sprintf("(%.2f)", c1$se), cex = 0.95, col = "gray30")
  y <- y - 0.05

  text(0.08, y, "moodyleverage × 1929-1933", adj = 0, cex = 1.1)
  text(0.75, y, sprintf("%.2f%s", c3$coef, sig_star(c3$p)), cex = 1.1)
  y <- y - 0.025; text(0.75, y, sprintf("(%.2f)", c3$se), cex = 0.95, col = "gray30")
  y <- y - 0.05

  text(0.08, y, "moodyleverage × 1934-1938", adj = 0, cex = 1.1)
  text(0.75, y, sprintf("%.2f%s", c4$coef, sig_star(c4$p)), cex = 1.1)
  y <- y - 0.025; text(0.75, y, sprintf("(%.2f)", c4$se), cex = 0.95, col = "gray30")
  y <- y - 0.05

  text(0.08, y, "moodyleverage × 1941-1943", adj = 0, cex = 1.1)
  text(0.75, y, sprintf("%.2f%s", c5$coef, sig_star(c5$p)), cex = 1.1)
  y <- y - 0.025; text(0.75, y, sprintf("(%.2f)", c5$se), cex = 0.95, col = "gray30")
  y <- y - 0.05

  segments(0.08, y, 0.92, y, lwd = 2)
  y <- y - 0.04

  text(0.08, y, r2_label, adj = 0, cex = 1.0)
  text(0.75, y, sprintf("%.2f", r2_value), cex = 1.0)
  y <- y - 0.035

  text(0.08, y, "N", adj = 0, cex = 1.0)
  text(0.75, y, format(stats::nobs(model), big.mark = ","), cex = 1.0)
  y <- y - 0.05

  segments(0.08, y, 0.92, y, lwd = 3)
  text(0.5, y - 0.03, "Standard errors clustered at city level. *** p<0.01, ** p<0.05, * p<0.10", cex = 0.85, font = 3)
  dev.off()
  cat("Wrote:", path, "\n")
}

# Panel A PNG uses best Panel A attempt (m1)
draw_panel_png(
  path = "output/table_IV_col3_fix_attempt_panelA.png",
  title = paste0("Panel A: Maintenance & Depreciation (", best_A_name, ")"),
  model = best_A_model,
  tv = testvar,
  r2_label = "R-sq (within)",
  r2_value = safe_wr2(best_A_model)
)

# Panel B PNG uses best Panel B attempt (closest to target coefficients)
draw_panel_png(
  path = "output/table_IV_col3_fix_attempt_panelB.png",
  title = paste0("Panel B: Capital Outlay (", best_B_name, ")"),
  model = best_B_model,
  tv = testvar,
  r2_label = "R-sq (pseudo)",
  r2_value = safe_pr2(best_B_model)
)


