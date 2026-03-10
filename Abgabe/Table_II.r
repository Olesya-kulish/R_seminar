##############################################################################
# Table II: Determinants of Pre-Depression Financial Leverage (1929)
# Purpose:
#   - Cross-sectional regressions explaining 1929 leverage (debt-to-assets)
#   - Test relationship between population, prior spending, and debt levels
#   - Use state fixed effects and clustered standard errors
# Columns:
#   - Col 1: Bonds/Assess ~ Population (1929)
#   - Col 2: Bonds/Assess ~ Population + Outlay Sum (1924-1929)
#   - Col 5: Debt/Revenue ~ Population + Prior Debt/Rev (1924) + Outlay Sum
# Output:
#   - CSV with coefficients, standard errors, and sample sizes
#   - PNG formatted table image
##############################################################################

# Load required packages
library(haven)      # Read Stata .dta files
library(dplyr)      # Data manipulation
library(fixest)     # Fixed effects regression with feols()
library(tibble)     # Tidy data frames
library(flextable)  # Export tables as PNG

# Load original city-level replication data
df_city <- read_dta('data/replication-data-city.dta')

# Filter to 1929 cross-section (year of Great Depression onset)
df <- df_city %>% filter(year == 1929)

################################################################################
# Estimate regression models for pre-Depression leverage determinants
################################################################################

# Column 1: Bonds/Assessed Value ~ Population (1929)
# - Standardized leverage outcome (bonds_to_assess29_lev_std)
# - Standardized population predictor (pop_i_std)
# - State fixed effects (state_)
# - Standard errors clustered at city level (id_)
m1 <- feols(
  bonds_to_assess29_lev_std ~ pop_i_std | state_,
  data = df,
  cluster = ~ id_
)

# Column 2: Bonds/Assessed Value ~ Population + Prior Spending (1924-1929)
# - Adds pc_outlay_24_29_std (average per capita spending 1924-1929)
m2 <- feols(
  bonds_to_assess29_lev_std ~ pop_i_std + pc_outlay_24_29_std | state_,
  data = df,
  cluster = ~ id_
)

# Column 5: Debt/Revenue ~ Population + Prior Debt/Revenue + Prior Spending
# - Different outcome: debt_to_rev29_lev_std (debt/revenue ratio)
# - Adds lagged dependent variable: debt_to_rev24_lev_std (persistence)
m5 <- feols(
  debt_to_rev29_lev_std ~ pop_i_std + debt_to_rev24_lev_std + pc_outlay_24_29_std | state_,
  data = df,
  cluster = ~ id_
)

# Create output directory
dir.create("output", showWarnings = FALSE)

################################################################################
# Display model summaries in console
################################################################################
cat("\n=== Table II: Column 1 ===\n")
print(summary(m1))
cat("\n=== Table II: Column 2 ===\n")
print(summary(m2))
cat("\n=== Table II: Column 5 ===\n")
print(summary(m5))

################################################################################
# Export results as CSV
################################################################################

# Helper function to extract coefficients + SEs + N from one model
coef_df <- function(mod, name) {
  tibble(
    model = name,
    term = names(coef(mod)),
    estimate = unname(coef(mod)),
    se = unname(se(mod)),
    n = nobs(mod)
  )
}

# Combine all three models into one CSV table
out_csv <- bind_rows(
  coef_df(m1, "Col1_BondsAssess"),
  coef_df(m2, "Col2_BondsAssess"),
  coef_df(m5, "Col5_DebtRev")
)

write.csv(out_csv, file = file.path("output", "table_II_cols_1_2_5.csv"), row.names = FALSE)
message("Wrote: ", normalizePath(file.path("output", "table_II_cols_1_2_5.csv"), winslash = "/"))

################################################################################
# Build formatted display table for export as PNG
################################################################################

# Helper to extract coefficient estimate (standard error) in publication format
safe_bse <- function(mod, term) {
  b <- tryCatch(coef(mod)[[term]], error = function(e) NA_real_)
  s <- tryCatch(se(mod)[[term]], error = function(e) NA_real_)
  if (is.na(b)) return("")
  paste0(round(b, 2), " (", round(s, 2), ")")
}

# Construct summary table with all estimates, diagnostics, and model info
summary_tab <- tibble(
  Variable = c(
    "Population (1929)",
    "Outlay Sum (1924–1929)",
    "Debt/Revenue (1924)",
    "N",
    "R² (within)",
    "State FE"
  ),
  `Col 1` = c(
    safe_bse(m1, "pop_i_std"),
    "",
    "",
    as.character(as.numeric(nobs(m1))[1]),
    as.character(as.numeric(round(r2(m1), 2))[1]),
    "✓"
  ),
  `Col 2` = c(
    safe_bse(m2, "pop_i_std"),
    safe_bse(m2, "pc_outlay_24_29_std"),
    "",
    as.character(as.numeric(nobs(m2))[1]),
    as.character(as.numeric(round(r2(m2), 2))[1]),
    "✓"
  ),
  `Col 5` = c(
    safe_bse(m5, "pop_i_std"),
    safe_bse(m5, "pc_outlay_24_29_std"),
    safe_bse(m5, "debt_to_rev24_lev_std"),
    as.character(as.numeric(nobs(m5))[1]),
    as.character(as.numeric(round(r2(m5), 2))[1]),
    "✓"
  )
)

# Export formatted table as PNG using flextable
ft <- flextable(summary_tab)
save_as_image(ft, path = file.path("output", "table_II_cols_1_2_5.png"))
message("Wrote: ", normalizePath(file.path("output", "table_II_cols_1_2_5.png"), winslash = "/"))
