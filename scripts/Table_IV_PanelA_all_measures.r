##############
## Table IV, Panel A - All Leverage Measures ##
## Looping through all 4 leverage measures
##############

library(haven)
library(dplyr)
library(fixest)
library(tibble)

## Load replication data
df_city <- read_dta('data/replication-data-city.dta')

## Create period indicators for DiD
df <- df_city %>%
  # Filter out years 1939 and 1940
  filter(!(year %in% c(1939, 1940))) %>%
  # Filter to check_moody range (same as Stata: check<0.2 & check>-0.2)
  filter(check_moody < 0.2 & check_moody > -0.2) %>%
  mutate(
    post_detail = case_when(
      year %in% 1924:1926 ~ 1,
      year %in% 1927:1928 ~ 2,  # base period
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

## Define the 4 leverage measures (same as Stata: bonds_to_assess29_lev int_to_rev29_lev debt_to_rev29_lev debt_total29_lev)
leverage_measures <- c(
  "bonds_to_assess29_lev_moody_std",
  "int_to_rev29_lev_moody_std",
  "debt_to_rev29_lev_moody_std",
  "debt_total29_lev_moody_std"
)

## Create output directory
dir.create("output", showWarnings = FALSE)

## Store all results
all_results <- list()
all_models <- list()

## Loop through each leverage measure
for (measure in leverage_measures) {
  
  cat("\n=== Processing:", measure, "===\n")
  
  ## Filter to complete cases
  df_panel_a <- df %>%
    filter(!is.na(post_detail)) %>%
    filter(!is.na(real_pc_outlay)) %>%
    filter(real_pc_outlay > 0) %>%
    filter(!is.na(pop_30), !is.na(pop_20_30)) %>%
    filter(!is.na(real_pc_rev_total_log), !is.na(L_real_pc_rev_total_log)) %>%
    filter(!is.na(region_), !is.na(.data[[measure]]))
  
  cat("N observations:", nrow(df_panel_a), "\n")
  
  ## Run Poisson FE model with all controls and interactions
  model <- fepois(
    real_pc_outlay ~ 
      i(post_detail, get(measure), ref = 2) +
      i(year, ref = 1928) +
      i(year, pop_30) + 
      i(year, pop_20_30) +
      real_pc_rev_total_log + 
      L_real_pc_rev_total_log +
      i(year, region_) |
      id_ + year,
    data = df_panel_a,
    cluster = ~ id_
  )
  
  ## Store model for table export
  all_models[[measure]] <- model
  
  ## Extract coefficients and standard errors
  coefs <- coef(model)
  ses <- se(model)
  
  ## Extract period x leverage interactions
  c1 <- c3 <- c4 <- c5 <- NA_real_
  se1 <- se3 <- se4 <- se5 <- NA_real_
  
  for (term in names(coefs)) {
    if (grepl("post_detail::1.*get", term)) { c1 <- coefs[[term]]; se1 <- ses[[term]] }
    if (grepl("post_detail::3.*get", term)) { c3 <- coefs[[term]]; se3 <- ses[[term]] }
    if (grepl("post_detail::4.*get", term)) { c4 <- coefs[[term]]; se4 <- ses[[term]] }
    if (grepl("post_detail::5.*get", term)) { c5 <- coefs[[term]]; se5 <- ses[[term]] }
  }
  
  ## Store results
  mean_y <- mean(df_panel_a$real_pc_outlay, na.rm = TRUE)
  sd_y <- sd(df_panel_a$real_pc_outlay, na.rm = TRUE)
  r2_val <- as.numeric(r2(model)[1])
  n_val <- as.numeric(nobs(model))
  
  all_results[[measure]] <- tibble(
    treatment = rep(measure, 4),
    outcome = rep("real_pc_outlay", 4),
    period = c("1924-1926", "1929-1933", "1934-1938", "1941-1943"),
    coefficient = c(c1, c3, c4, c5),
    se = c(se1, se3, se4, se5),
    n = rep(n_val, 4),
    r2 = rep(r2_val, 4),
    mean_y = rep(mean_y, 4),
    sd_y = rep(sd_y, 4)
  )
  
  cat("Summary for", measure, "\n")
  print(summary(model))
}

## Combine all results into one table
results_table <- bind_rows(all_results)

## Export combined results
write.csv(results_table, file = file.path("output", "table_IV_panelA_all_measures.csv"), row.names = FALSE)
cat("\n\nWrote:", normalizePath(file.path("output", "table_IV_panelA_all_measures.csv"), winslash = "/"), "\n")

## Display results
cat("\n=== COMBINED RESULTS ===\n")
print(results_table)

## ==========================================
## Create PNG table image
## ==========================================

png(
  file.path("output", "table_IV_panelA_all_measures.png"),
  width = 1400,
  height = 1000,
  res = 150
)

par(mar = c(1, 1, 1, 1), family = "sans")
plot.new()

# Title
text(0.5, 0.97, "Table IV, Panel A: Moody Leverage and Capital Outlays", font = 2, cex = 1.6)
text(0.5, 0.93, "Outcome: Real Per-Capita Capital Outlay", cex = 1.1)

# Column headers
text(0.12, 0.88, "", font = 2, cex = 1.1)
text(0.28, 0.88, "Bonds/Assess", font = 2, cex = 1.1)
text(0.45, 0.88, "Int/Rev", font = 2, cex = 1.1)
text(0.62, 0.88, "Debt/Rev", font = 2, cex = 1.1)
text(0.79, 0.88, "Debt/Capita", font = 2, cex = 1.1)

# Top line
segments(0.08, 0.86, 0.92, 0.86, lwd = 3)

# Period labels and coefficients
y_pos <- 0.82
periods <- c("1924-1926", "1929-1933", "1934-1938", "1941-1943")

for (i in 1:4) {
  period <- periods[i]
  
  # Period label
  text(0.08, y_pos, paste("leverage x", period), adj = 0, cex = 1.0)
  
  # Get coefficients for each measure
  for (j in 1:4) {
    measure <- leverage_measures[j]
    coef_val <- results_table %>% 
      filter(treatment == measure, period == !!period) %>% 
      pull(coefficient)
    se_val <- results_table %>% 
      filter(treatment == measure, period == !!period) %>% 
      pull(se)
    
    x_pos <- 0.08 + (j - 0.5) * 0.17
    
    if (!is.na(coef_val)) {
      text(x_pos, y_pos, sprintf("%.3f", coef_val), cex = 1.0, font = 1)
    }
  }
  
  y_pos <- y_pos - 0.04
  
  # SE row
  text(0.08, y_pos, "", adj = 0, cex = 1.0)
  
  for (j in 1:4) {
    measure <- leverage_measures[j]
    se_val <- results_table %>% 
      filter(treatment == measure, period == !!period) %>% 
      pull(se)
    
    x_pos <- 0.08 + (j - 0.5) * 0.17
    
    if (!is.na(se_val)) {
      text(x_pos, y_pos, sprintf("(%.3f)", se_val), cex = 0.9, col = "gray30")
    }
  }
  
  y_pos <- y_pos - 0.06
}

# Line before controls
segments(0.08, y_pos, 0.92, y_pos, lwd = 2)
y_pos <- y_pos - 0.04

# Statistics section
text(0.08, y_pos, "City FE", adj = 0, cex = 1.0)
text(0.28, y_pos, "✓", cex = 1.2)
text(0.45, y_pos, "✓", cex = 1.2)
text(0.62, y_pos, "✓", cex = 1.2)
text(0.79, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.04

text(0.08, y_pos, "Year FE", adj = 0, cex = 1.0)
text(0.28, y_pos, "✓", cex = 1.2)
text(0.45, y_pos, "✓", cex = 1.2)
text(0.62, y_pos, "✓", cex = 1.2)
text(0.79, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.04

text(0.08, y_pos, "Pop Controls", adj = 0, cex = 1.0)
text(0.28, y_pos, "✓", cex = 1.2)
text(0.45, y_pos, "✓", cex = 1.2)
text(0.62, y_pos, "✓", cex = 1.2)
text(0.79, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.04

text(0.08, y_pos, "Revenue Controls", adj = 0, cex = 1.0)
text(0.28, y_pos, "✓", cex = 1.2)
text(0.45, y_pos, "✓", cex = 1.2)
text(0.62, y_pos, "✓", cex = 1.2)
text(0.79, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.04

text(0.08, y_pos, "Region x Year FE", adj = 0, cex = 1.0)
text(0.28, y_pos, "✓", cex = 1.2)
text(0.45, y_pos, "✓", cex = 1.2)
text(0.62, y_pos, "✓", cex = 1.2)
text(0.79, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.05

# Line before stats
segments(0.08, y_pos, 0.92, y_pos, lwd = 2)
y_pos <- y_pos - 0.04

# Get first model's stats as representative
first_measure <- leverage_measures[1]
stats <- results_table %>% filter(treatment == first_measure) %>% slice(1)

text(0.08, y_pos, "R-sq (pseudo)", adj = 0, cex = 1.0)
text(0.28, y_pos, sprintf("%.3f", stats$r2[1]), cex = 1.0)
text(0.45, y_pos, sprintf("%.3f", stats$r2[1]), cex = 1.0)
text(0.62, y_pos, sprintf("%.3f", stats$r2[1]), cex = 1.0)
text(0.79, y_pos, sprintf("%.3f", stats$r2[1]), cex = 1.0)
y_pos <- y_pos - 0.04

text(0.08, y_pos, "N", adj = 0, cex = 1.0)
text(0.28, y_pos, sprintf("%d", stats$n[1]), cex = 1.0)
text(0.45, y_pos, sprintf("%d", stats$n[1]), cex = 1.0)
text(0.62, y_pos, sprintf("%d", stats$n[1]), cex = 1.0)
text(0.79, y_pos, sprintf("%d", stats$n[1]), cex = 1.0)
y_pos <- y_pos - 0.04

text(0.08, y_pos, "Mean(y)", adj = 0, cex = 1.0)
text(0.28, y_pos, sprintf("%.2f", stats$mean_y[1]), cex = 1.0)
text(0.45, y_pos, sprintf("%.2f", stats$mean_y[1]), cex = 1.0)
text(0.62, y_pos, sprintf("%.2f", stats$mean_y[1]), cex = 1.0)
text(0.79, y_pos, sprintf("%.2f", stats$mean_y[1]), cex = 1.0)
y_pos <- y_pos - 0.04

text(0.08, y_pos, "SD(y)", adj = 0, cex = 1.0)
text(0.28, y_pos, sprintf("%.2f", stats$sd_y[1]), cex = 1.0)
text(0.45, y_pos, sprintf("%.2f", stats$sd_y[1]), cex = 1.0)
text(0.62, y_pos, sprintf("%.2f", stats$sd_y[1]), cex = 1.0)
text(0.79, y_pos, sprintf("%.2f", stats$sd_y[1]), cex = 1.0)
y_pos <- y_pos - 0.03

# Bottom line
segments(0.08, y_pos, 0.92, y_pos, lwd = 3)

dev.off()

message("Wrote: ", normalizePath(file.path("output", "table_IV_panelA_all_measures.png"), winslash = "/"))
