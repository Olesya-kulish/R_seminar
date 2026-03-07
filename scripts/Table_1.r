##############################################################################
# Table 1: City-Level Summary Statistics (Panels A and C)
# Purpose:
#   - Panel A: City revenue, expenditure, and debt variables (all years 1924-1943)
#   - Panel C: Bank shocks, population, crime, grants (year 1930 cross-section)
# Output:
#   - CSV files with N, mean, SD, median, 25th/75th percentiles for each variable
#   - PNG images of formatted tables
##############################################################################

# Clear workspace for fresh environment
rm(list = ls())

# Load required packages for data handling, regression, and table generation
library(haven)      # Read Stata .dta files
library(dplyr)      # Data manipulation (filter, mutate, etc.)
library(fixest)     # For later regression models (not used in this script)
library(tibble)     # Data frame construction
library(purrr)      # map_dfr() for efficient iteration
library(flextable)  # Export tables as PNG images

# Load original replication data (city-level panel and individual-level micro)
# These are the original .dta files from the replication package.
df_city <- read_dta('data/replication-data-city.dta')
df_micro <- read_dta("data/replication-data-micro.dta")

##Define variables and labels for city summary statistics
vars <- c(
  "pop_i_k",
  "real_pc_rev_total",
  "real_pc_rev_tax",
  "real_pc_rev_nontax",
  "real_pc_rev_debt",
  "real_pc_rev_nontax_nondebt",
  "real_pc_maint_dep_total",
  "real_pc_maint_dep_gen",
  "real_pc_maint_dep_health",
  "real_pc_maint_dep_road",
  "real_pc_maint_dep_pp",
  "real_pc_maint_dep_charity",
  "real_pc_maint_dep_rec",
  "real_pc_maint_dep_school",
  "real_pc_maint_dep_other",
  "real_pc_pse",
  "real_pc_interest",
  "real_pc_outlay",
  "real_pc_pay_other",
  "real_pc_debt_total",
  "real_pc_debt_bond",
  "real_pc_assess_total",
  "default",
  "default_city",
  "bonds_to_assess",
  "int_to_rev",
  "debt_to_rev"
)
labels <- c(
  "Population (k)",
  "Total revenue, excluding debt issuance",
  "Tax revenue",
  "All non-tax revenue (earnings)",
  "Debt receipts",
  "All other non-tax, non-debt receipts",
  "Payments: Total service",
  "Payments: government administration",
  "Payments: health and sanitation",
  "Payments: roads and highways",
  "Payments: protection of persons and property",
  "Payments: charities, welfare, and corrections",
  "Payments: recreation",
  "Payments: school and libraries",
  "Other service payments",
  "Public utilites",
  "Interest",
  "Capital outlays",
  "All other non-maintenance, non-outlay payments",
  "Total debt",
  "Total bonded debt",
  "Assessed value of property",
  "Defaulted 1930 - 1937 (any district)",
  "Defaulted 1930 - 1937 (city)",
  "Bond debt / assessed value",
  "Interest payment / tax revenue",
  "Debt / total revenue"
)

# Filter to non-missing observations for revenue variable to match published N
df <- df_city %>% filter(!is.na(real_pc_rev_total))

##Compute summary statistics
compute_summary <- function(x) {
  n <- sum(!is.na(x))
  tibble(
    N = n,
    Mean = mean(x, na.rm = TRUE),
    SD = sd(x, na.rm = TRUE),
    Median = stats::median(x, na.rm = TRUE),
    `25 pct` = as.numeric(stats::quantile(x, 0.25, na.rm = TRUE, type = 2)),
    `75 pct` = as.numeric(stats::quantile(x, 0.75, na.rm = TRUE, type = 2))
  )
}
# Build summary table by iterating over all variables and applying compute_summary
out <- map_dfr(seq_along(vars), function(i) {
  v <- vars[i]
  x <- df[[v]]
  tibble(Variable = labels[i]) %>% bind_cols(compute_summary(x))
})

# Round all numeric columns to 2 decimals for publication format
out_fmt <- out %>% mutate(across(where(is.numeric), ~round(., 2)))

# Ensure output directory exists
dir.create("output", showWarnings = FALSE)

# Write Panel A summary statistics as CSV (machine-readable)
write.csv(out_fmt, file = file.path("output", "summary_stats_city1.csv"), row.names = FALSE)

# Export as PNG image for easy human inspection
ft <- flextable(out_fmt)
save_as_image(ft, path = file.path("output", "summary_stats_city1.png"))


################################################################################
# PANEL C: Other City and County Data (year 1930 cross-section)
# Purpose:
#   - Bank shocks, credit conditions (Depression-era)
#   - Population changes, city age, pre-1929 spending levels
#   - Federal grants (WPA, RFC)
#   - Crime rates, death rates
################################################################################
vars <- c(
    "bank_shock",
    "delta_loan_31_29_tr",
    "years_since_w",
    "share_1925_1929_t",
    "pop_20_30",
    "city_age",
    "outlay_24_29",
    "WPA_pc",
    "RFC_pc",
    "murder1_pc",
    "rape_pc",
    "robbery_pc",
    "aggasu_pc",
    "burglary_pc",
    "autothft_pc",
    "death_rate_31",
    "pop_30_40"
)

labels <- c(
  "Sus. Bank Deposits (1930-33)",
  "Delta Log (Loans 1931-1929)",
  "Debt Age",
  "Debt Share (1925-1929)",
  "Delta Log (Population 1920-1930)",
  "City age in 1930",
  "Total outlays (1924-1929)/capita",
  "WPA grants/capita",
  "RFC grants/capita",
  "Murder rate/100k",
  "Rape rate/100k",
  "Robbery rate/100k",
  "Assault rate/100k",
  "Burglary rate/100k",
  "Auto theft rate/100k",
  "Communicable disease deaths/100k",
  "Delta Log(Pop 1930-1940)"
)


# Filter to year 1930 cross-section for Panel C variables
df2 <- df_city %>% filter(year == 1930)

# Redefine compute_summary function for Panel C (same logic as Panel A)
compute_summary <- function(x) {
  n <- sum(!is.na(x))
  tibble(
    N = n,
    Mean = mean(x, na.rm = TRUE),
    SD = sd(x, na.rm = TRUE),
    Median = stats::median(x, na.rm = TRUE),
    `25 pct` = as.numeric(stats::quantile(x, 0.25, na.rm = TRUE, type = 2)),
    `75 pct` = as.numeric(stats::quantile(x, 0.75, na.rm = TRUE, type = 2))
  )
}

# Build summary table for Panel C
out2 <- map_dfr(seq_along(vars), function(i) {
  v <- vars[i]
  x <- df2[[v]]
  tibble(Variable = labels[i]) %>% bind_cols(compute_summary(x))
})
# Round Panel C summary statistics to 2 decimals
out2_fmt <- out2 %>% mutate(across(where(is.numeric), ~round(., 2)))

# Write Panel C summary as CSV
write.csv(out2_fmt, file = file.path("output", "summary_stats_city_panelC.csv"), row.names = FALSE)

# Export Panel C as PNG image
ft2 <- flextable(out2_fmt)
save_as_image(ft2, path = file.path("output", "summary_stats_city_panelC.png"))
