#!/usr/bin/env Rscript
## Script: make_city_summary.R
## Purpose: Recreate Table I (city-level summary statistics) from the
## replication data `replication-data-city.dta`.

required_pkgs <- c("haven", "dplyr", "tibble", "xtable", "purrr")
missing_pkgs <- required_pkgs[!(required_pkgs %in% installed.packages()[, "Package"])]
if (length(missing_pkgs)) {
  stop(paste0("Please install required packages: ", paste(missing_pkgs, collapse = ", "),
              "\nRun: install.packages(c('", paste(missing_pkgs, collapse = "','"), "'))"))
}

library(haven)
library(dplyr)
library(tibble)
library(xtable)
library(purrr)

infile <- file.path("data", "replication-data-city.dta")
if (!file.exists(infile)) stop("Data file not found: ", infile)

city <- read_dta(infile)

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

## Match Stata: use only observations with non-missing `real_pc_rev_total`
df <- city %>% filter(!is.na(real_pc_rev_total))

compute_summary <- function(x) {
  n <- sum(!is.na(x))
  if (n == 0) return(tibble(N = 0L, Mean = NA_real_, SD = NA_real_, Median = NA_real_, `25 pct` = NA_real_, `75 pct` = NA_real_))
  tibble(
    N = n,
    Mean = mean(x, na.rm = TRUE),
    SD = sd(x, na.rm = TRUE),
    Median = stats::median(x, na.rm = TRUE),
    `25 pct` = as.numeric(stats::quantile(x, 0.25, na.rm = TRUE)),
    `75 pct` = as.numeric(stats::quantile(x, 0.75, na.rm = TRUE))
  )
}

out <- map_dfr(seq_along(vars), function(i) {
  v <- vars[i]
  x <- df[[v]]
  tibble(Variable = labels[i]) %>% bind_cols(compute_summary(x))
})

dir.create("output", showWarnings = FALSE)
write.csv(out, file = file.path("output", "summary_stats_city.csv"), row.names = FALSE)

## Save LaTeX: user can refine formatting; this produces a basic table
latex_file <- file.path("output", "summary_stats_city.tex")
cat(print(xtable::xtable(out, caption = "City Level Revenue and Expenditure, 1924--1943"), include.rownames = FALSE), file = latex_file)

message("Wrote: ", normalizePath(file.path("output", "summary_stats_city.csv"), winslash = "/"))
message("Wrote: ", normalizePath(latex_file, winslash = "/"))
