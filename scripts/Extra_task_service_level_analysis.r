##############################################################################
# Extra task: Service-level spending cuts during the Depression
#
# Goal:
#   Test whether leverage effects differ across service categories
#   (roads, health, schools, recreation, etc.) rather than only total spending.
#
# Design:
#   - Outcome: service-specific log real per-capita maintenance/depreciation
#   - Treatment: debt_to_rev29_lev_moody_std (standardized)
#   - DiD structure: i(post_detail, ref = 2) * leverage
#   - Controls aligned with main Table III/IV style
#
# Outputs:
#   - output/extra_task_service_level_coefficients.csv
#   - output/extra_task_service_level_key_periods.csv
#   - output/extra_task_service_level_analysis.png
##############################################################################

library(haven)
library(dplyr)
library(fixest)

# ------------------------------
# 1) Load data and sample filter
# ------------------------------

df <- read_dta("data/replication-data-city.dta")

# Stata-style fallback
filter_var <- if ("check" %in% names(df)) "check" else "check_moody"

df0 <- df %>%
  filter(.data[[filter_var]] < 0.2, .data[[filter_var]] > -0.2) %>%
  mutate(
    id_ = as.factor(id_),
    year = as.integer(year),
    region = as.factor(region_),
    post_detail = as.integer(post_detail)
  )

leverage_var <- "debt_to_rev29_lev_moody_std"
stopifnot(leverage_var %in% names(df0))

cat("Using filter:", filter_var, "\n")
cat("Sample size before model-specific NA drops:", nrow(df0), "\n")

# ------------------------------
# 2) Outcomes to analyze
# ------------------------------

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

service_outcomes <- service_outcomes[service_outcomes %in% names(df0)]
if (length(service_outcomes) == 0) stop("No service-level log outcomes found.")

# Nicely formatted labels
pretty_label <- function(v) {
  x <- gsub("real_pc_maint_dep_", "", v)
  x <- gsub("_log", "", x)
  tools::toTitleCase(x)
}

# ------------------------------
# 3) Estimation helper
# ------------------------------

extract_interactions <- function(model, lev_name, outcome) {
  ct <- coeftable(model)
  pcol <- intersect(c("Pr(>|t|)", "Pr(>|z|)", "Pr(>|chi|)"), colnames(ct))[1]

  terms <- paste0(lev_name, ":post_detail::", c(1, 3, 4, 5))
  periods <- c("1924-1926", "1929-1933", "1934-1938", "1941-1943")

  rows <- lapply(seq_along(terms), function(i) {
    term <- terms[i]
    if (term %in% rownames(ct)) {
      data.frame(
        outcome = outcome,
        period = periods[i],
        estimate = unname(ct[term, "Estimate"]),
        se = unname(ct[term, "Std. Error"]),
        p_value = unname(ct[term, pcol]),
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
  })

  out <- bind_rows(rows)
  out$N <- nobs(model)
  out$R2_within <- as.numeric(fitstat(model, "wr2"))
  out
}

run_one_outcome <- function(yvar) {
  fml <- as.formula(paste0(
    yvar, " ~ ",
    "i(post_detail, ref = 2) * ", leverage_var, " + ",
    "i(year, ref = 1928) + ",
    "i(year, pop_30, ref = 1928) + ",
    "i(year, pop_20_30, ref = 1928) + ",
    "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) + ",
    "i(year, region_) | id_"
  ))

  model <- feols(
    fml = fml,
    data = df0,
    vcov = ~ id_,
    panel.id = ~ id_ + year
  )

  extract_interactions(model, leverage_var, yvar)
}

# ------------------------------
# 4) Run all outcomes
# ------------------------------

all_results <- bind_rows(lapply(service_outcomes, run_one_outcome)) %>%
  mutate(service = sapply(outcome, pretty_label))

# Focus table for core crisis periods
key_periods <- all_results %>%
  filter(period %in% c("1929-1933", "1934-1938")) %>%
  arrange(period, estimate)

# ------------------------------
# 5) Save CSV outputs
# ------------------------------

dir.create("output", showWarnings = FALSE)
write.csv(all_results, "output/extra_task_service_level_coefficients.csv", row.names = FALSE)
write.csv(key_periods, "output/extra_task_service_level_key_periods.csv", row.names = FALSE)

# ------------------------------
# 6) PNG summary output
# ------------------------------

# Create a compact summary table for 1929-33 and 1934-38
wide <- key_periods %>%
  select(service, period, estimate, se, p_value) %>%
  mutate(
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
) %>%
  arrange(service)

png("output/extra_task_service_level_analysis.png", width = 1400, height = 950, res = 150)
par(mar = c(1, 1, 1, 1), family = "sans")
plot.new()

text(0.5, 0.98, "Extra Task: Service-level Leverage Effects", font = 2, cex = 1.5)
text(0.5, 0.95, "Outcome-specific DiD coefficients (log real per-capita maintenance/depreciation)", font = 3, cex = 1.0)
segments(0.05, 0.92, 0.95, 0.92, lwd = 3)

# Header
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
     "Stars: *** p<0.01, ** p<0.05, * p<0.10.\nSpecification follows Table III/IV controls with city FE and clustered SEs.",
     cex = 0.9, font = 3)

dev.off()

cat("Wrote: output/extra_task_service_level_coefficients.csv\n")
cat("Wrote: output/extra_task_service_level_key_periods.csv\n")
cat("Wrote: output/extra_task_service_level_analysis.png\n")

print(key_periods %>% select(service, period, estimate, se, p_value) %>% arrange(period, estimate))
