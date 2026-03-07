# Quick diagnostic script - run this in RStudio console
# Source this: source("diagnostic_quick_check.r")

library(haven)
library(dplyr)

## Load data once
df_raw <- read_dta('data/replication-data-city.dta')

cat("\n")
cat("=" %+% rep("=", 70), "\n")
cat("TABLE IV, PANEL A: DIAGNOSTIC CHECK\n")
cat("=" %+% rep("=", 70), "\n\n")

## Check 1: check_moody variable
cat("STEP 1: Examining check_moody variable\n")
cat("-" %+% rep("-", 60), "\n")
cat("N total:", nrow(df_raw), "\n")
cat("check_moody: min=", round(min(df_raw$check_moody, na.rm=T), 4),
    ", max=", round(max(df_raw$check_moody, na.rm=T), 4), "\n")
cat("check_moody missing:", sum(is.na(df_raw$check_moody)), "\n\n")

check_dist <- df_raw %>%
  filter(!is.na(check_moody)) %>%
  mutate(range = case_when(
    check_moody < -0.2 ~ "< -0.2",
    check_moody >= -0.2 & check_moody <= 0.2 ~ "IN RANGE [-0.2, 0.2]",
    check_moody > 0.2 ~ "> 0.2"
  )) %>%
  group_by(range) %>%
  summarise(count = n(), pct = round(100*n()/nrow(.), 1), .groups='drop')

print(check_dist)

## Check 2: Year filter impact
cat("\n\nSTEP 2: Impact of year filters\n")
cat("-" %+% rep("-", 60), "\n")
df_temp <- df_raw %>% filter(!is.na(check_moody))
cat("N with valid check_moody:", nrow(df_temp), "\n")

df_temp <- df_temp %>% filter(!(year %in% c(1939, 1940)))
cat("N after excluding 1939-1940:", nrow(df_temp), "\n")

df_temp <- df_temp %>% filter(check_moody < 0.2 & check_moody > -0.2)
cat("N after check filter [-0.2, 0.2]:", nrow(df_temp), "\n")

## Check 3: Poisson sample (no zeros)
cat("\n\nSTEP 3: Impact of real_pc_outlay > 0 filter\n")
cat("-" %+% rep("-", 60), "\n")
df_with_outcome <- df_temp %>% filter(!is.na(real_pc_outlay))
cat("N with real_pc_outlay:", nrow(df_with_outcome), "\n")

df_with_outcome_positive <- df_with_outcome %>% filter(real_pc_outlay > 0)
cat("N with real_pc_outlay > 0:", nrow(df_with_outcome_positive), "\n")
cat("Zeros dropped:", nrow(df_with_outcome) - nrow(df_with_outcome_positive), "\n")

## Summary for Table IV
cat("\n")
cat("=" %+% rep("=", 70), "\n")
cat("TABLE IV EXPECTED N: 3829 | YOUR N: " %+% nrow(df_with_outcome_positive) %+% "\n")
cat("Difference:", nrow(df_with_outcome_positive) - 3829, "\n")
cat("=" %+% rep("=", 70), "\n\n")

################################################################
cat("\n\n")
cat("=" %+% rep("=", 70), "\n")
cat("TABLE III, PANEL A: DIAGNOSTIC CHECK\n")
cat("=" %+% rep("=", 70), "\n\n")

## Build Table III sample step by step
df_t3 <- df_raw %>%
  mutate(leverage = bonds_to_assess29_lev_std) %>%
  filter(!(year %in% c(1939, 1940)))

cat("STEP 1: After year exclusion\n")
cat("-" %+% rep("-", 60), "\n")
cat("N:", nrow(df_t3), "\n")
cat("Unique cities:", n_distinct(df_t3$id_), "\n")
cat("Unique years:", paste(sort(unique(df_t3$year)), collapse=", "), "\n\n")

## Build complete cases
df_t3_step <- df_t3 %>%
  mutate(
    post_detail = case_when(
      year %in% 1924:1926 ~ 1,
      year %in% 1927:1928 ~ 2,
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

cat("STEP 2: After post_detail creation\n")
cat("-" %+% rep("-", 60), "\n")
cat("N with post_detail:", nrow(df_t3_step %>% filter(!is.na(post_detail))), "\n\n")

cat("STEP 3: Progressively add filters\n")
cat("-" %+% rep("-", 60), "\n")

n1 <- nrow(df_t3_step %>% filter(!is.na(post_detail)))
cat("After post_detail:", n1, "\n")

n2 <- nrow(df_t3_step %>% filter(!is.na(post_detail), !is.na(real_pc_maint_dep_total_log)))
cat("After outcome variable:", n2, " (lost", n1-n2, ")\n")

n3 <- nrow(df_t3_step %>% filter(!is.na(post_detail), !is.na(real_pc_maint_dep_total_log), 
                                  !is.na(pop_30), !is.na(pop_20_30)))
cat("After population:", n3, " (lost", n2-n3, ")\n")

n4 <- nrow(df_t3_step %>% filter(!is.na(post_detail), !is.na(real_pc_maint_dep_total_log),
                                  !is.na(pop_30), !is.na(pop_20_30),
                                  !is.na(real_pc_rev_total_log), !is.na(L_real_pc_rev_total_log)))
cat("After revenue:", n4, " (lost", n3-n4, ")\n")

n5 <- nrow(df_t3_step %>% filter(!is.na(post_detail), !is.na(real_pc_maint_dep_total_log),
                                  !is.na(pop_30), !is.na(pop_20_30),
                                  !is.na(real_pc_rev_total_log), !is.na(L_real_pc_rev_total_log),
                                  !is.na(leverage)))
cat("After leverage:", n5, " (lost", n4-n5, ")\n\n")

## Balance check
df_complete <- df_t3_step %>%
  filter(!is.na(post_detail), !is.na(real_pc_maint_dep_total_log),
         !is.na(pop_30), !is.na(pop_20_30),
         !is.na(real_pc_rev_total_log), !is.na(L_real_pc_rev_total_log),
         !is.na(leverage))

n_cities <- n_distinct(df_complete$id_)
n_years_expected <- 17  # 1924-1926, 1927-1928, 1929-1933, 1934-1938, 1941-1943
n_expected <- n_cities * n_years_expected

cat("STEP 4: Balance check\n")
cat("-" %+% rep("-", 60), "\n")
cat("Unique cities in final sample:", n_cities, "\n")
cat("Years per city (expected if balanced):", n_years_expected, "\n")
cat("Expected N if balanced:", n_expected, "\n")
cat("Actual N:", nrow(df_complete), "\n")
cat("Excess observations:", nrow(df_complete) - n_expected, "\n\n")

if (nrow(df_complete) == n_expected) {
  cat("✓ BALANCED PANEL\n")
} else {
  cat("✗ UNBALANCED PANEL - Extra rows suggest duplicates or missing exclusion\n")
}

## Check year distribution
cat("\nYear distribution in final sample:\n")
year_dist <- df_complete %>% count(year) %>% arrange(year)
print(year_dist)

cat("\n")
cat("=" %+% rep("=", 70), "\n")
cat("TABLE III EXPECTED N: 10903 | YOUR N: " %+% nrow(df_complete) %+% "\n")
cat("Difference:", nrow(df_complete) - 10903, "\n")
cat("=" %+% rep("=", 70), "\n")
