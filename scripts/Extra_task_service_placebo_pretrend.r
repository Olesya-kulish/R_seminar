##############################################################################
# Extra task add-on: Placebo pre-trend test for service-level analysis
#
# Purpose:
#   Test whether leverage already predicts differential spending changes BEFORE
#   the main crisis period (falsification / pre-trend check).
#
# Design:
#   - Restrict to pre-crisis years: 1924-1928
#   - Fake treatment period: 1927-1928 (placebo_post = 1), baseline 1924-1926
#   - Coefficient of interest: placebo_post × leverage
#   - If near zero / insignificant, supports main DiD interpretation.
#
# Outputs:
#   - output/extra_task_service_placebo_pretrend.csv
#   - output/extra_task_service_placebo_pretrend.png
##############################################################################

library(haven)
library(dplyr)
library(fixest)

# ------------------------------
# 1) Data prep
# ------------------------------

df <- read_dta("data/replication-data-city.dta")
filter_var <- if ("check" %in% names(df)) "check" else "check_moody"

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

panel <- df %>%
  filter(.data[[filter_var]] < 0.2, .data[[filter_var]] > -0.2) %>%
  filter(year >= 1924, year <= 1928) %>%
  mutate(
    id_ = as.factor(id_),
    year = as.integer(year),
    region = as.factor(region_),
    leverage = debt_to_rev29_lev_moody_std,
    placebo_post = ifelse(year >= 1927, 1, 0)
  )

cat("Using filter:", filter_var, "\n")
cat("Pre-trend sample years:", min(panel$year, na.rm = TRUE), "-", max(panel$year, na.rm = TRUE), "\n")
cat("Rows before model-specific NA drops:", nrow(panel), "\n")

# ------------------------------
# 2) Estimation helper
# ------------------------------

extract_placebo <- function(model, outcome_name) {
  ct <- coeftable(model)
  pcol <- intersect(c("Pr(>|t|)", "Pr(>|z|)", "Pr(>|chi|)"), colnames(ct))[1]

  # robust term detection for interaction placebo_post x leverage
  term_candidates <- rownames(ct)[grepl("placebo_post.*:leverage|leverage.*:placebo_post", rownames(ct))]
  term <- if (length(term_candidates) > 0) term_candidates[1] else NA_character_

  if (!is.na(term)) {
    est <- unname(ct[term, "Estimate"])
    se <- unname(ct[term, "Std. Error"])
    p <- unname(ct[term, pcol])
  } else {
    est <- NA_real_
    se <- NA_real_
    p <- NA_real_
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

run_placebo <- function(yvar) {
  # use no region×year here for stability in short pre-period window
  fml <- as.formula(paste0(
    yvar, " ~ placebo_post * leverage + ",
    "i(year, ref = 1926) + ",
    "i(year, pop_30, ref = 1926) + ",
    "i(year, pop_20_30, ref = 1926) + ",
    "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) | id_"
  ))

  m <- feols(
    fml,
    data = panel,
    vcov = ~ id_,
    panel.id = ~ id_ + year
  )

  extract_placebo(m, yvar)
}

results <- bind_rows(lapply(service_outcomes, run_placebo))

pretty_label <- function(v) {
  x <- gsub("real_pc_maint_dep_", "", v)
  x <- gsub("_log", "", x)
  tools::toTitleCase(x)
}

results <- results %>%
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

# ------------------------------
# 3) Outputs
# ------------------------------

dir.create("output", showWarnings = FALSE)
write.csv(results, "output/extra_task_service_placebo_pretrend.csv", row.names = FALSE)

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
for (i in 1:nrow(results)) {
  text(0.08, y, results$service[i], adj = 0, cex = 0.95)
  text(0.62, y, results$coef_txt[i], cex = 0.95)
  text(0.82, y, results$se_txt[i], cex = 0.90, col = "gray30")
  y <- y - 0.072
}

segments(0.06, y + 0.03, 0.94, y + 0.03, lwd = 2)
text(0.5, 0.08,
     "Interpretation: coefficients near zero and insignificant support parallel pre-trends.\nStars: *** p<0.01, ** p<0.05, * p<0.10",
     cex = 0.9, font = 3)

dev.off()

cat("Wrote: output/extra_task_service_placebo_pretrend.csv\n")
cat("Wrote: output/extra_task_service_placebo_pretrend.png\n")

print(results %>% select(service, placebo_coef, se, p_value, N))
