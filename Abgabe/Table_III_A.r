##############################################################################
# Table III, Panel A: Financial Leverage and Service Expenditure
# Purpose:
#   - Difference-in-differences estimation of leverage impact on city spending
#   - Treatment: 1929 leverage (bonds/assessed value, standardized)
#   - Outcome: real per capita maintenance & depreciation (logged)
#   - Time periods: 1924-1943 (excluding 1939-1940)
# Columns:
#   - Col 1: Basic DiD (city FE + year FE)
#   - Col 4: Full model (adds population controls, revenue controls)
# Output:
#   - CSV with interaction coefficients for each period
#   - PNG formatted table image
##############################################################################

# Load required packages
library(haven)    # Read Stata .dta files
library(dplyr)    # Data manipulation
library(fixest)   # Fixed effects regression (feols)
library(tibble)   # Tidy data frames
library(flextable) # Export tables as images

# Load original city-level replication data
df_city <- read_dta('data/replication-data-city.dta')

################################################################################
# Data preparation (Stata-aligned)
################################################################################

# Stata code uses: gen test = bonds_to_assess29_lev_std
# Keep original `post_detail` from the dataset and avoid manual reconstruction.
# Keep full panel years so lag handling stays consistent with xtset/xtreg behavior.
df <- df_city %>%
  mutate(
    test = bonds_to_assess29_lev_std,
    id_ = as.integer(id_),
    year = as.integer(year)
  )

################################################################################
# Column 1: Basic DiD (City FE + Year FE only)
################################################################################

# Estimate: Stata equivalent
# xtreg real_pc_maint_dep_total_log ib2.post_detail##c.test ib1928.year, fe c(id_)
m1 <- feols(
  real_pc_maint_dep_total_log ~ i(post_detail, test, ref = 2) + i(year, ref = 1928) | id_,
  data = df,
  panel.id = ~ id_ + year,
  cluster = ~ id_
)

################################################################################
# Column 4: Full DiD with population and revenue controls
################################################################################

# Estimate Column 4: Stata equivalent
# xtreg real_pc_maint_dep_total_log ib2.post_detail##c.test ib1928.year
#       c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log L1.real_pc_rev_total_log, fe c(id_)
# - i(year, pop_30): interaction between year FE and 1930 population
# - i(year, pop_20_30): interaction between year FE and 1920-1930 pop growth
# - real_pc_rev_total_log: current revenue (control for fiscal capacity)
# - l(real_pc_rev_total_log, 1): lagged revenue built from panel.id
m4 <- feols(
  real_pc_maint_dep_total_log ~ 
    i(post_detail, test, ref = 2) +
    i(year, ref = 1928) +
    i(year, pop_30, ref = 1928) + 
    i(year, pop_20_30, ref = 1928) +
    real_pc_rev_total_log + 
    l(real_pc_rev_total_log, 1) | 
    id_,
  data = df,
  panel.id = ~ id_ + year,
  cluster = ~ id_
)

# Create output directory
dir.create("output", showWarnings = FALSE)

################################################################################
# Display model summaries
################################################################################
cat("\n=== Table III Panel A: Column 1 ===\n")
print(summary(m1))
cat("\n=== Table III Panel A: Column 4 ===\n")
print(summary(m4))

################################################################################
# Extract coefficients for formatted table export
################################################################################

# Helper to extract leverage × period interaction coefficient + SE
safe_coef <- function(mod, period) {
  term <- paste0("post_detail::", period, ":test")
  b <- tryCatch(coef(mod)[[term]], error = function(e) NA_real_)
  s <- tryCatch(se(mod)[[term]], error = function(e) NA_real_)
  if (is.na(b)) return("")
  paste0(round(b, 2), " (", round(s, 2), ")")
}

# Compute mean and SD of outcome using the estimation sample from Column 1
idx_m1 <- fixest::obs(m1)
y_m1 <- df$real_pc_maint_dep_total_log[idx_m1]
ymean_m1 <- mean(y_m1, na.rm = TRUE)
ysd_m1 <- sd(y_m1, na.rm = TRUE)

################################################################################
# Build formatted summary table
################################################################################

summary_tab <- tibble(
  Variable = c(
    "Leverage × 1924-1926",
    "Leverage × 1929-1933",
    "Leverage × 1934-1938",
    "Leverage × 1941-1943",
    "N",
    "R² (within)",
    "City FE",
    "Year FE",
    "1930 Pop × Year",
    "Δ1920–30 Pop × Year",
    "Revenue",
    "Mean(y)",
    "SD(y)"
  ),
  `Col 1` = c(
    safe_coef(m1, 1),
    safe_coef(m1, 3),
    safe_coef(m1, 4),
    safe_coef(m1, 5),
    as.character(nobs(m1)),
    as.character(round(r2(m1, type = "wr2"), 2)),
    "✓",
    "✓",
    "",
    "",
    "",
    as.character(round(ymean_m1, 2)),
    as.character(round(ysd_m1, 2))
  ),
  `Col 4` = c(
    safe_coef(m4, 1),
    safe_coef(m4, 3),
    safe_coef(m4, 4),
    safe_coef(m4, 5),
    as.character(nobs(m4)),
    as.character(round(r2(m4, type = "wr2"), 2)),
    "✓",
    "✓",
    "✓",
    "✓",
    "✓",
    "",
    ""
  )
)

################################################################################
# Export table outputs
################################################################################

# Export as CSV
write.csv(summary_tab, file = file.path("output", "table_III_A_cols_1_4.csv"), row.names = FALSE)
message("Wrote: ", normalizePath(file.path("output", "table_III_A_cols_1_4.csv"), winslash = "/"))

# Export as PNG image
ft <- flextable(summary_tab)
save_as_image(ft, path = file.path("output", "table_III_A_cols_1_4.png"))
message("Wrote: ", normalizePath(file.path("output", "table_III_A_cols_1_4.png"), winslash = "/"))
