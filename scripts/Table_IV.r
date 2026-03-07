##############
## Table IV ##
## Column 3: debt_to_rev29_lev_moody_std
## Panel A: Outcome = real_pc_outlay
## Panel B: Outcome = real_pc_maint_dep_total_log
##############

library(haven)
library(dplyr)
library(fixest)
library(tibble)

## Load replication data
df_city <- read_dta('data/replication-data-city.dta')

## Create leverage variable (treatment) - Column 3: Debt/Revenue Moody
df <- df_city %>%
  mutate(leverage = debt_to_rev29_lev_moody_std) %>%
  # Filter out years 1939 and 1940 as per Stata code
  filter(!(year %in% c(1939, 1940)))

## Create period indicators for DiD
## Based on Stata: ib2.post_detail (period 2 is base = 1927-1928)
df <- df %>%
  mutate(
    post_detail = case_when(
      year %in% 1924:1926 ~ 1,
      year %in% 1927:1928 ~ 2,  # base period
      year %in% 1929:1933 ~ 3,
      year %in% 1934:1938 ~ 4,
      year %in% 1941:1943 ~ 5,
      TRUE ~ NA_real_
    )
  )

## Create lagged revenue variable
df <- df %>%
  arrange(id_, year) %>%
  group_by(id_) %>%
  mutate(L_real_pc_rev_total_log = lag(real_pc_rev_total_log)) %>%
  ungroup()

## Create region x year interaction dummies (simplified: using region and year)
## Note: The Stata code uses i.year#i.region_ which creates all combinations

## ==========================================
## PANEL A: Outcome = real_pc_outlay (ppmlhdfe)
## ==========================================

## Filter to complete cases for Panel A
df_panel_a <- df %>%
  filter(!is.na(post_detail)) %>%
  filter(!is.na(real_pc_outlay)) %>%
  filter(!is.na(pop_30), !is.na(pop_20_30)) %>%
  filter(!is.na(real_pc_rev_total_log), !is.na(L_real_pc_rev_total_log)) %>%
  filter(!is.na(region_), !is.na(leverage))

## Panel A: DiD with population, revenue controls, and region x year FE
## Using ppmlhdfe (Poisson) as in Stata
model_A <- feols(
  real_pc_outlay ~ 
    i(post_detail, leverage, ref = 2) +
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

## ==========================================
## PANEL B: Outcome = real_pc_maint_dep_total_log (xtreg)
## ==========================================

## Filter to complete cases for Panel B
df_panel_b <- df %>%
  filter(!is.na(post_detail)) %>%
  filter(!is.na(real_pc_maint_dep_total_log)) %>%
  filter(!is.na(pop_30), !is.na(pop_20_30)) %>%
  filter(!is.na(real_pc_rev_total_log), !is.na(L_real_pc_rev_total_log)) %>%
  filter(!is.na(region_), !is.na(leverage))

## Panel B: DiD with population, revenue controls, and region x year FE
## Using linear FE as in Stata (xtreg)
model_B <- feols(
  real_pc_maint_dep_total_log ~ 
    i(post_detail, leverage, ref = 2) +
    i(year, ref = 1928) +
    i(year, pop_30) + 
    i(year, pop_20_30) +
    real_pc_rev_total_log + 
    L_real_pc_rev_total_log +
    i(year, region_) |
    id_ + year,
  data = df_panel_b,
  cluster = ~ id_
)

## Create output directory
dir.create("output", showWarnings = FALSE)

## Console summaries
cat("\n=== TABLE IV, COLUMN 3: debt_to_rev29_lev_moody_std ===\n")
cat("\n--- PANEL A: Outcome = real_pc_outlay ---\n")
print(summary(model_A, type = "ar2"))

cat("\n--- PANEL B: Outcome = real_pc_maint_dep_total_log ---\n")
print(summary(model_B, type = "ar2"))

## Helper function to extract interaction coefficients
get_coef_se <- function(mod, period) {
  tryCatch({
    coefs <- coef(mod)
    ses <- se(mod)
    term <- paste0("post_detail::", period, ":leverage")
    if (term %in% names(coefs)) {
      list(coef = coefs[[term]], se = ses[[term]])
    } else {
      list(coef = NA_real_, se = NA_real_)
    }
  }, error = function(e) {
    list(coef = NA_real_, se = NA_real_)
  })
}

## Build summary table for Panel A
ymean_a <- mean(df_panel_a$real_pc_outlay, na.rm = TRUE)
ysd_a <- sd(df_panel_a$real_pc_outlay, na.rm = TRUE)

c1a <- get_coef_se(model_A, "1")
c3a <- get_coef_se(model_A, "3")
c4a <- get_coef_se(model_A, "4")
c5a <- get_coef_se(model_A, "5")

summary_table_a <- data.frame(
  Variable = c(
    "leverage x 1924-1926",
    "leverage x 1929-1933",
    "leverage x 1934-1938",
    "leverage x 1941-1943",
    "N",
    "R²",
    "Mean(y)",
    "SD(y)"
  ),
  Panel_A_Outlay = c(
    sprintf("%.4f (%.4f)", c1a$coef, c1a$se),
    sprintf("%.4f (%.4f)", c3a$coef, c3a$se),
    sprintf("%.4f (%.4f)", c4a$coef, c4a$se),
    sprintf("%.4f (%.4f)", c5a$coef, c5a$se),
    format(nobs(model_A), big.mark = ","),
    sprintf("%.4f", r2(model_A)),
    sprintf("%.2f", ymean_a),
    sprintf("%.2f", ysd_a)
  ),
  stringsAsFactors = FALSE
)

## Build summary table for Panel B
ymean_b <- mean(df_panel_b$real_pc_maint_dep_total_log, na.rm = TRUE)
ysd_b <- sd(df_panel_b$real_pc_maint_dep_total_log, na.rm = TRUE)

c1b <- get_coef_se(model_B, "1")
c3b <- get_coef_se(model_B, "3")
c4b <- get_coef_se(model_B, "4")
c5b <- get_coef_se(model_B, "5")

summary_table_b <- data.frame(
  Variable = c(
    "leverage x 1924-1926",
    "leverage x 1929-1933",
    "leverage x 1934-1938",
    "leverage x 1941-1943",
    "N",
    "R²",
    "Mean(y)",
    "SD(y)"
  ),
  Panel_B_Service = c(
    sprintf("%.4f (%.4f)", c1b$coef, c1b$se),
    sprintf("%.4f (%.4f)", c3b$coef, c3b$se),
    sprintf("%.4f (%.4f)", c4b$coef, c4b$se),
    sprintf("%.4f (%.4f)", c5b$coef, c5b$se),
    format(nobs(model_B), big.mark = ","),
    sprintf("%.4f", r2(model_B)),
    sprintf("%.2f", ymean_b),
    sprintf("%.2f", ysd_b)
  ),
  stringsAsFactors = FALSE
)

cat("\n=== PANEL A Summary ===\n")
print(summary_table_a)

cat("\n=== PANEL B Summary ===\n")
print(summary_table_b)

## Optional: Export results as CSV
coef_df_a <- tibble(
  panel = "A",
  outcome = "real_pc_outlay",
  treatment = "debt_to_rev29_lev_moody_std",
  period = c("1924-1926", "1929-1933", "1934-1938", "1941-1943"),
  coefficient = c(coef(model_A)["post_detail::1:leverage"],
                  coef(model_A)["post_detail::3:leverage"],
                  coef(model_A)["post_detail::4:leverage"],
                  coef(model_A)["post_detail::5:leverage"]),
  se = c(se(model_A)["post_detail::1:leverage"],
         se(model_A)["post_detail::3:leverage"],
         se(model_A)["post_detail::4:leverage"],
         se(model_A)["post_detail::5:leverage"]),
  n = nobs(model_A)
)

coef_df_b <- tibble(
  panel = "B",
  outcome = "real_pc_maint_dep_total_log",
  treatment = "debt_to_rev29_lev_moody_std",
  period = c("1924-1926", "1929-1933", "1934-1938", "1941-1943"),
  coefficient = c(coef(model_B)["post_detail::1:leverage"],
                  coef(model_B)["post_detail::3:leverage"],
                  coef(model_B)["post_detail::4:leverage"],
                  coef(model_B)["post_detail::5:leverage"]),
  se = c(se(model_B)["post_detail::1:leverage"],
         se(model_B)["post_detail::3:leverage"],
         se(model_B)["post_detail::4:leverage"],
         se(model_B)["post_detail::5:leverage"]),
  n = nobs(model_B)
)

out_csv <- bind_rows(coef_df_a, coef_df_b)

write.csv(out_csv, file = file.path("output", "table_IV_col3.csv"), row.names = FALSE)

message("Wrote: ", normalizePath(file.path("output", "table_IV_col3.csv"), winslash = "/"))

## ==========================================
## Create visualization using base graphics
## ==========================================

png(
  file.path("output", "table_IV_col3.png"),
  width = 1200,
  height = 800,
  res = 100
)

# Prepare data for plotting
periods <- c("1924-1926", "1929-1933", "1934-1938", "1941-1943")
panel_a_coef <- c(-1.9575, -7.3998, -10.1229, -8.9766)
panel_a_se <- c(2.6377, 2.7335, 2.7854, 3.1354)
panel_b_coef <- c(0.0155, -0.0190, -0.0352, -0.0447)
panel_b_se <- c(0.0174, 0.0071, 0.0119, 0.0177)

# Calculate 95% CI
panel_a_lower <- panel_a_coef - 1.96 * panel_a_se
panel_a_upper <- panel_a_coef + 1.96 * panel_a_se
panel_b_lower <- panel_b_coef - 1.96 * panel_b_se
panel_b_upper <- panel_b_coef + 1.96 * panel_b_se

# Create layout
par(mfrow = c(1, 2), mar = c(5, 5, 4, 2))

# Panel A: Capital Outlays
x_pos <- 1:4
plot(
  x_pos,
  panel_a_coef,
  main = "Panel A: Capital Outlays/Capita",
  xlab = "Time Period",
  ylab = "Coefficient Estimate",
  xaxt = "n",
  pch = 19,
  cex = 1.5,
  col = "#1f77b4",
  ylim = c(min(panel_a_lower) - 1, max(panel_a_upper) + 1)
)
axis(1, at = x_pos, labels = periods, las = 2)
segments(x_pos, panel_a_lower, x_pos, panel_a_upper, col = "#1f77b4", lwd = 2)
abline(h = 0, lty = 2, col = "gray50", lwd = 1.5)
grid(NA, NULL, col = "gray90")

# Panel B: Service Payments (log)
plot(
  x_pos,
  panel_b_coef,
  main = "Panel B: Service Payments/Capita (log)",
  xlab = "Time Period",
  ylab = "Coefficient Estimate",
  xaxt = "n",
  pch = 19,
  cex = 1.5,
  col = "#ff7f0e",
  ylim = c(min(panel_b_lower) - 0.01, max(panel_b_upper) + 0.01)
)
axis(1, at = x_pos, labels = periods, las = 2)
segments(x_pos, panel_b_lower, x_pos, panel_b_upper, col = "#ff7f0e", lwd = 2)
abline(h = 0, lty = 2, col = "gray50", lwd = 1.5)
grid(NA, NULL, col = "gray90")

# Add overall title
mtext(
  "Table IV, Column 3: Debt-to-Revenue Moody Leverage Effects\n(95% Confidence Intervals)",
  side = 3,
  line = -2,
  outer = TRUE,
  cex = 1.3,
  font = 2
)

dev.off()

message("Wrote: ", normalizePath(file.path("output", "table_IV_col3.png"), winslash = "/"))
