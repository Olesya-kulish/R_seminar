##############################################################################
# Table IV (FIX ATTEMPT - SEPARATE SCRIPT)
# Column 3: debt_to_rev29_lev_moody_std
#
# Purpose:
#   Try a closer Stata-aligned implementation without touching the original file.
#
# Main alignment changes vs current main script:
# 1) Use original `post_detail` from data (no manual reconstruction)
# 2) Do not pre-drop 1939/1940; rely on non-missing `post_detail`
# 3) Use panel lag directly in formula: l(real_pc_rev_total_log, 1)
# 4) Panel B uses city FE only (| id_), matching xtreg ..., fe c(id_)
##############################################################################

library(haven)
library(dplyr)
library(fixest)
library(tibble)
library(flextable)

# -------------------------
# Load and prepare data
# -------------------------
df_city <- read_dta("data/replication-data-city.dta")

# Stata logic: gen test_moody = debt_to_rev29_lev_moody_std
# Sample restriction: if check < 0.2 & check > -0.2
# In this dataset the corresponding variable is `check_moody`.
df <- df_city %>%
  mutate(
    test_moody = debt_to_rev29_lev_moody_std,
    id_ = as.integer(id_),
    year = as.integer(year)
  ) %>%
  filter(check_moody < 0.2, check_moody > -0.2) %>%
  filter(!is.na(post_detail))

# -------------------------
# Panel A (Poisson, ppmlhdfe-like)
# Stata target:
# ppmlhdfe real_pc_outlay ib2.post_detail##c.test_moody ib1928.year
#          c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log
#          L1.real_pc_rev_total_log i.year#i.region_ if check<0.2 & check>-0.2,
#          absorb(id_ year) cl(id_)
# -------------------------
model_A_fix <- fepois(
  real_pc_outlay ~
    i(post_detail, test_moody, ref = 2) +
    i(year, ref = 1928) +
    i(year, pop_30, ref = 1928) +
    i(year, pop_20_30, ref = 1928) +
    real_pc_rev_total_log +
    l(real_pc_rev_total_log, 1) +
    i(year, region_) |
    id_ + year,
  data = df,
  panel.id = ~ id_ + year,
  cluster = ~ id_
)

# -------------------------
# Panel B (OLS FE)
# Stata target:
# xtreg real_pc_maint_dep_total_log ib2.post_detail##c.test_moody ib1928.year
#       c.pop_30##i.year c.pop_20_30##i.year real_pc_rev_total_log
#       L1.real_pc_rev_total_log i.year#i.region_ if check<0.2 & check>-0.2,
#       fe c(id_)
# -------------------------
model_B_fix <- feols(
  real_pc_maint_dep_total_log ~
    i(post_detail, test_moody, ref = 2) +
    i(year, ref = 1928) +
    i(year, pop_30, ref = 1928) +
    i(year, pop_20_30, ref = 1928) +
    real_pc_rev_total_log +
    l(real_pc_rev_total_log, 1) +
    i(year, region_) |
    id_,
  data = df,
  panel.id = ~ id_ + year,
  cluster = ~ id_
)

# -------------------------
# Helpers
# -------------------------
get_interaction <- function(mod, period) {
  rn <- names(coef(mod))
  cand <- rn[grepl(paste0("post_detail::", period), rn) & grepl("test_moody", rn)]
  if (length(cand) == 0) return(list(coef = NA_real_, se = NA_real_))
  term <- cand[[1]]
  list(
    coef = unname(coef(mod)[term]),
    se = unname(se(mod)[term])
  )
}

fmt_bse <- function(x) {
  if (is.na(x$coef) || is.na(x$se)) return("")
  paste0(round(x$coef, 2), " (", round(x$se, 2), ")")
}

scalar_first <- function(x) {
  as.character(round(as.numeric(x)[1], 3))
}

# Collect key periods
a1 <- get_interaction(model_A_fix, 1)
a3 <- get_interaction(model_A_fix, 3)
a4 <- get_interaction(model_A_fix, 4)
a5 <- get_interaction(model_A_fix, 5)

b1 <- get_interaction(model_B_fix, 1)
b3 <- get_interaction(model_B_fix, 3)
b4 <- get_interaction(model_B_fix, 4)
b5 <- get_interaction(model_B_fix, 5)

# Outcome moments from estimation samples
idx_a <- fixest::obs(model_A_fix)
idx_b <- fixest::obs(model_B_fix)

ymean_a <- mean(df$real_pc_outlay[idx_a], na.rm = TRUE)
ysd_a <- sd(df$real_pc_outlay[idx_a], na.rm = TRUE)
ymean_b <- mean(df$real_pc_maint_dep_total_log[idx_b], na.rm = TRUE)
ysd_b <- sd(df$real_pc_maint_dep_total_log[idx_b], na.rm = TRUE)

# -------------------------
# Output tables (separate filenames)
# -------------------------
dir.create("output", showWarnings = FALSE)

summary_tab <- tibble(
  Variable = c(
    "moody leverage × 1924-1926",
    "moody leverage × 1929-1933",
    "moody leverage × 1934-1938",
    "moody leverage × 1941-1943",
    "N",
    "R²",
    "City FE",
    "Year FE",
    "1930 Pop × Year",
    "Δ1920–30 Pop × Year",
    "Revenue",
    "Region × Year",
    "Mean(y)",
    "SD(y)"
  ),
  `Panel A (Poisson) fix attempt` = c(
    fmt_bse(a1),
    fmt_bse(a3),
    fmt_bse(a4),
    fmt_bse(a5),
    as.character(nobs(model_A_fix)),
    scalar_first(r2(model_A_fix)),
    "✓", "✓", "✓", "✓", "✓", "✓",
    as.character(round(ymean_a, 2)),
    as.character(round(ysd_a, 2))
  ),
  `Panel B (OLS) fix attempt` = c(
    fmt_bse(b1),
    fmt_bse(b3),
    fmt_bse(b4),
    fmt_bse(b5),
    as.character(nobs(model_B_fix)),
    scalar_first(r2(model_B_fix, type = "wr2")),
    "✓", "✓", "✓", "✓", "✓", "✓",
    as.character(round(ymean_b, 2)),
    as.character(round(ysd_b, 2))
  )
)

write.csv(summary_tab, file = "output/table_IV_col3_fix_attempt_summary.csv", row.names = FALSE)

coef_tab <- tibble(
  panel = c(rep("A", 4), rep("B", 4)),
  estimator = c(rep("Poisson", 4), rep("OLS", 4)),
  period = rep(c("1924-1926", "1929-1933", "1934-1938", "1941-1943"), 2),
  coef = c(a1$coef, a3$coef, a4$coef, a5$coef, b1$coef, b3$coef, b4$coef, b5$coef),
  se = c(a1$se, a3$se, a4$se, a5$se, b1$se, b3$se, b4$se, b5$se),
  n = c(rep(nobs(model_A_fix), 4), rep(nobs(model_B_fix), 4))
)
write.csv(coef_tab, file = "output/table_IV_col3_fix_attempt_coefs.csv", row.names = FALSE)

ft <- flextable(summary_tab)
save_as_image(ft, path = "output/table_IV_col3_fix_attempt_summary.png")

# -------------------------
# Extra diagnostic: Panel B coefficient comparison across all Table IV columns
# -------------------------
all_vars <- c(
  "bonds_to_assess29_lev_moody_std",
  "int_to_rev29_lev_moody_std",
  "debt_to_rev29_lev_moody_std",
  "debt_total29_lev_moody_std"
)

diag_rows <- lapply(all_vars, function(vv) {
  dtmp <- df %>% mutate(test_moody = .data[[vv]])
  mtmp <- feols(
    real_pc_maint_dep_total_log ~
      i(post_detail, test_moody, ref = 2) +
      i(year, ref = 1928) +
      i(year, pop_30, ref = 1928) +
      i(year, pop_20_30, ref = 1928) +
      real_pc_rev_total_log +
      l(real_pc_rev_total_log, 1) +
      i(year, region_) |
      id_,
    data = dtmp,
    panel.id = ~ id_ + year,
    cluster = ~ id_
  )

  p5 <- get_interaction(mtmp, 5)
  tibble(
    variable = vv,
    n = nobs(mtmp),
    coef_1941_1943 = p5$coef,
    se_1941_1943 = p5$se
  )
})

diag_tab <- bind_rows(diag_rows)
write.csv(diag_tab, file = "output/table_IV_panelB_allcols_diagnostic.csv", row.names = FALSE)

cat("\n=== TABLE IV FIX ATTEMPT COMPLETED ===\n")
cat("Panel A N:", nobs(model_A_fix), "(Stata target approx: 3829)\n")
cat("Panel B N:", nobs(model_B_fix), "\n")
cat("Wrote: output/table_IV_col3_fix_attempt_summary.csv\n")
cat("Wrote: output/table_IV_col3_fix_attempt_coefs.csv\n")
cat("Wrote: output/table_IV_col3_fix_attempt_summary.png\n")
cat("Wrote: output/table_IV_panelB_allcols_diagnostic.csv\n")
