##############################################################################
# Extra Task: Service-level analysis + placebo pre-trend test
#
# Purpose:
#   1) Service-level heterogeneity:
#      Estimate leverage effects separately by service category.
#   2) Placebo pre-trend falsification:
#      Test whether leverage already predicts differential changes before crisis.
#
# Data:
#   - data/replication-data-city.dta
#
# Core treatment variable:
#   - debt_to_rev29_lev_moody_std
#
# Sample filter:
#   - Stata-style fallback logic: use `check` if present, else `check_moody`
#   - keep observations with -0.2 < filter < 0.2
#
# Output files:
#   Service-level (main extra task):
#   - output/extra_task_service_level_coefficients.csv
#   - output/extra_task_service_level_key_periods.csv
#   - output/extra_task_service_level_analysis.png
#
#   Placebo pre-trend (validation add-on):
#   - output/extra_task_service_placebo_pretrend.csv
#   - output/extra_task_service_placebo_pretrend.png
##############################################################################

library(haven)
library(dplyr)
library(fixest)

##############################################################################
# 1) Shared setup
##############################################################################

df <- read_dta("data/replication-data-city.dta")
# Mirror the Stata workflow: prefer `check`, otherwise use `check_moody`
filter_var <- if ("check" %in% names(df)) "check" else "check_moody"
leverage_var <- "debt_to_rev29_lev_moody_std"

service_outcomes <- c(
  "real_pc_maint_dep_gen_log",
  "real_pc_maint_dep_health_log",
  "real_pc_maint_dep_road_log",
  "real_pc_maint_dep_pp_log",
  "real_pc_maint_dep_charity_log",
  "real_pc_maint_dep_rec_log",
  "real_pc_maint_dep_school_log",
  "real_pc_maint_dep_other_log",
  "real_pc_maint_dep_total_log"
)
service_outcomes <- service_outcomes[service_outcomes %in% names(df)]

if (length(service_outcomes) == 0) stop("No service-level outcomes found.")
if (!(leverage_var %in% names(df))) stop("Leverage variable not found in data.")

pretty_label <- function(v) {
  x <- gsub("real_pc_maint_dep_", "", v)
  x <- gsub("_log", "", x)
  tools::toTitleCase(x)
}

p_col <- function(ct) intersect(c("Pr(>|t|)", "Pr(>|z|)", "Pr(>|chi|)"), colnames(ct))[1]

dir.create("output", showWarnings = FALSE)

cat("Using filter variable:", filter_var, "\n")
cat("Number of service outcomes:", length(service_outcomes), "\n")

##############################################################################
# 2) Service-level heterogeneity analysis (main extra task)
##############################################################################

panel_main <- df %>%
  filter(.data[[filter_var]] < 0.2, .data[[filter_var]] > -0.2) %>%
  mutate(
    # Ensure panel/fixed-effect identifiers use the expected types for fixest
    id_ = as.factor(id_),
    year = as.integer(year),
    region = as.factor(region_),
    post_detail = as.integer(post_detail)
  )

extract_interactions <- function(model, lev_name, outcome) {
  ct <- coeftable(model)
  pv <- p_col(ct)
  # Pull only the leverage x period interactions reported in the paper-style table
  terms <- paste0(lev_name, ":post_detail::", c(1, 3, 4, 5))
  periods <- c("1924-1926", "1929-1933", "1934-1938", "1941-1943")

  out <- lapply(seq_along(terms), function(i) {
    t <- terms[i]
    if (t %in% rownames(ct)) {
      data.frame(
        outcome = outcome,
        period = periods[i],
        estimate = unname(ct[t, "Estimate"]),
        se = unname(ct[t, "Std. Error"]),
        p_value = unname(ct[t, pv]),
        stringsAsFactors = FALSE
      )
    } else {
      data.frame(
        outcome = outcome,
        period = periods[i],
        estimate = NA_real_,
        se = NA_real_,
        p_value = NA_real_,
        stringsAsFactors = FALSE
      )
    }
  }) %>% bind_rows()

  out$N <- nobs(model)
  out$R2_within <- as.numeric(fitstat(model, "wr2"))
  out
}

run_service_model <- function(yvar) {
  # Event-study-style DiD: period dummies interacted with leverage, plus time-varying controls
  fml <- as.formula(paste0(
    yvar, " ~ ",
    "i(post_detail, ref = 2) * ", leverage_var, " + ",
    "i(year, ref = 1928) + ",
    "i(year, pop_30, ref = 1928) + ",
    "i(year, pop_20_30, ref = 1928) + ",
    "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) + ",
    "i(year, region_) | id_"
  ))

  m <- feols(fml, data = panel_main, vcov = ~ id_, panel.id = ~ id_ + year)
  extract_interactions(m, leverage_var, yvar)
}

service_results <- bind_rows(lapply(service_outcomes, run_service_model)) %>%
  mutate(service = sapply(outcome, pretty_label))

service_key <- service_results %>%
  # Keep crisis/post-crisis windows for the compact headline table
  filter(period %in% c("1929-1933", "1934-1938")) %>%
  arrange(period, estimate)

write.csv(service_results, "output/extra_task_service_level_coefficients.csv", row.names = FALSE)
write.csv(service_key, "output/extra_task_service_level_key_periods.csv", row.names = FALSE)

# PNG for main extra task
wide <- service_key %>%
  select(service, period, estimate, se, p_value) %>%
  mutate(
    # Add significance stars for quick visual scanning in the PNG output
    stars = case_when(
      is.na(p_value) ~ "",
      p_value < 0.01 ~ "***",
      p_value < 0.05 ~ "**",
      p_value < 0.10 ~ "*",
      TRUE ~ ""
    ),
    coef_txt = ifelse(is.na(estimate), "NA", sprintf("%.2f%s", estimate, stars)),
    se_txt = ifelse(is.na(se), "NA", sprintf("(%.2f)", se))
  ) %>%
  select(service, period, coef_txt, se_txt)

p_2933 <- wide %>% filter(period == "1929-1933") %>% select(service, coef_txt, se_txt)
p_3438 <- wide %>% filter(period == "1934-1938") %>% select(service, coef_txt, se_txt)

summary_tab <- full_join(
  p_2933 %>% rename(coef_2933 = coef_txt, se_2933 = se_txt),
  p_3438 %>% rename(coef_3438 = coef_txt, se_3438 = se_txt),
  by = "service"
) %>% arrange(service)

png("output/extra_task_service_level_analysis.png", width = 1400, height = 950, res = 150)
par(mar = c(1, 1, 1, 1), family = "sans")
plot.new()
text(0.5, 0.98, "Extra Task: Service-level Leverage Effects", font = 2, cex = 1.5)
text(0.5, 0.95, "Outcome-specific DiD coefficients (log real per-capita maintenance/depreciation)", font = 3, cex = 1.0)
segments(0.05, 0.92, 0.95, 0.92, lwd = 3)
text(0.08, 0.885, "Service", adj = 0, font = 2, cex = 1.05)
text(0.46, 0.885, "1929-1933", font = 2, cex = 1.05)
text(0.68, 0.885, "1934-1938", font = 2, cex = 1.05)
text(0.88, 0.885, "SEs", font = 2, cex = 1.05)
segments(0.05, 0.86, 0.95, 0.86, lwd = 2)

y <- 0.83
for (i in 1:nrow(summary_tab)) {
  text(0.08, y, summary_tab$service[i], adj = 0, cex = 0.95)
  text(0.46, y, summary_tab$coef_2933[i], cex = 0.95)
  text(0.68, y, summary_tab$coef_3438[i], cex = 0.95)
  text(0.86, y, summary_tab$se_2933[i], cex = 0.85, col = "gray30")
  text(0.93, y, summary_tab$se_3438[i], cex = 0.85, col = "gray30")
  y <- y - 0.072
}
segments(0.05, y + 0.03, 0.95, y + 0.03, lwd = 2)
text(0.5, 0.08,
     "Stars: *** p<0.01, ** p<0.05, * p<0.10. Specification follows Table III/IV controls with city FE and clustered SEs.",
     cex = 0.9, font = 3)
dev.off()

##############################################################################
# 3) Placebo pre-trend test (validation add-on)
##############################################################################

panel_pre <- df %>%
  filter(.data[[filter_var]] < 0.2, .data[[filter_var]] > -0.2) %>%
  filter(year >= 1924, year <= 1928) %>%
  mutate(
    id_ = as.factor(id_),
    year = as.integer(year),
    leverage = .data[[leverage_var]],
    # Fake treatment timing inside the pre-period (1927-28 vs 1924-26)
    placebo_post = ifelse(year >= 1927, 1, 0)
  )

extract_placebo <- function(model, outcome_name) {
  ct <- coeftable(model)
  pv <- p_col(ct)
  # Match either interaction ordering because fixest can print both forms
  cand <- rownames(ct)[grepl("placebo_post.*:leverage|leverage.*:placebo_post", rownames(ct))]
  term <- if (length(cand) > 0) cand[1] else NA_character_

  if (!is.na(term)) {
    est <- unname(ct[term, "Estimate"])
    se <- unname(ct[term, "Std. Error"])
    p <- unname(ct[term, pv])
  } else {
    est <- NA_real_; se <- NA_real_; p <- NA_real_
  }

  data.frame(
    outcome = outcome_name,
    placebo_coef = est,
    se = se,
    p_value = p,
    N = nobs(model),
    R2_within = as.numeric(fitstat(model, "wr2")),
    stringsAsFactors = FALSE
  )
}

run_placebo_model <- function(yvar) {
  # Same control structure as the main spec, restricted to pre-crisis years
  fml <- as.formula(paste0(
    yvar, " ~ placebo_post * leverage + ",
    "i(year, ref = 1926) + ",
    "i(year, pop_30, ref = 1926) + ",
    "i(year, pop_20_30, ref = 1926) + ",
    "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) | id_"
  ))
  m <- feols(fml, data = panel_pre, vcov = ~ id_, panel.id = ~ id_ + year)
  extract_placebo(m, yvar)
}

placebo_results <- bind_rows(lapply(service_outcomes, run_placebo_model)) %>%
  mutate(
    service = sapply(outcome, pretty_label),
    stars = case_when(
      is.na(p_value) ~ "",
      p_value < 0.01 ~ "***",
      p_value < 0.05 ~ "**",
      p_value < 0.10 ~ "*",
      TRUE ~ ""
    ),
    coef_txt = ifelse(is.na(placebo_coef), "NA", sprintf("%.3f%s", placebo_coef, stars)),
    se_txt = ifelse(is.na(se), "NA", sprintf("(%.3f)", se))
  ) %>%
  arrange(placebo_coef)

write.csv(placebo_results, "output/extra_task_service_placebo_pretrend.csv", row.names = FALSE)

png("output/extra_task_service_placebo_pretrend.png", width = 1300, height = 900, res = 150)
par(mar = c(1, 1, 1, 1), family = "sans")
plot.new()
text(0.5, 0.98, "Placebo Pre-trend Test (1924-1928)", font = 2, cex = 1.5)
text(0.5, 0.95, "Coefficient shown: placebo_post (1927-28) × leverage", font = 3, cex = 1.0)
segments(0.06, 0.92, 0.94, 0.92, lwd = 3)
text(0.08, 0.88, "Service", adj = 0, font = 2, cex = 1.05)
text(0.62, 0.88, "Placebo coef", font = 2, cex = 1.05)
text(0.82, 0.88, "SE", font = 2, cex = 1.05)
segments(0.06, 0.855, 0.94, 0.855, lwd = 2)

y <- 0.825
for (i in 1:nrow(placebo_results)) {
  text(0.08, y, placebo_results$service[i], adj = 0, cex = 0.95)
  text(0.62, y, placebo_results$coef_txt[i], cex = 0.95)
  text(0.82, y, placebo_results$se_txt[i], cex = 0.90, col = "gray30")
  y <- y - 0.072
}
segments(0.06, y + 0.03, 0.94, y + 0.03, lwd = 2)
text(0.5, 0.08,
     "Interpretation: coefficients near zero and insignificant support parallel pre-trends. Stars: *** p<0.01, ** p<0.05, * p<0.10",
     cex = 0.9, font = 3)
dev.off()

##############################################################################
# 4) Console summary
##############################################################################

cat("\nWrote: output/extra_task_service_level_coefficients.csv\n")
cat("Wrote: output/extra_task_service_level_key_periods.csv\n")
cat("Wrote: output/extra_task_service_level_analysis.png\n")
cat("Wrote: output/extra_task_service_placebo_pretrend.csv\n")
cat("Wrote: output/extra_task_service_placebo_pretrend.png\n")

cat("\nTop service-level results (1929-1933 and 1934-1938):\n")
print(service_key %>% select(service, period, estimate, se, p_value) %>% arrange(period, estimate))

cat("\nPlacebo pre-trend coefficients:\n")
print(placebo_results %>% select(service, placebo_coef, se, p_value, N))
