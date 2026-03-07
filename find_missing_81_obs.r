# Detailed diagnostic for Table IV observation loss
# Find where the 81 missing observations are going

library(haven)
library(dplyr)
library(fixest)

df_city <- read_dta('data/replication-data-city.dta')

cat("\n")
cat(paste(rep("=", 70), collapse=""), "\n")
cat("TABLE IV DETAILED DIAGNOSTIC: Finding the Missing 81 Observations\n")
cat(paste(rep("=", 70), collapse=""), "\n\n")

## Step-by-step observation tracking
cat("STEP 1: Initial data\n")
cat(paste(rep("-", 60), collapse=""), "\n")
n0 <- nrow(df_city)
cat("Total observations in raw data:", n0, "\n\n")

## Step 2: Create leverage variable
cat("STEP 2: Create debt_to_rev29_lev_moody_std\n")
cat(paste(rep("-", 60), collapse=""), "\n")
df <- df_city %>%
  mutate(leverage = debt_to_rev29_lev_moody_std)
n1 <- nrow(df %>% filter(!is.na(leverage)))
cat("With leverage variable:", n1, "\n")
cat("Lost from missing leverage:", n0 - n1, "\n\n")

## Step 3: Exclude years 1939-1940
cat("STEP 3: Exclude years 1939-1940\n")
cat(paste(rep("-", 60), collapse=""), "\n")
df <- df %>% filter(!(year %in% c(1939, 1940)))
n2 <- nrow(df)
cat("After year exclusion:", n2, "\n")
cat("Lost from year exclusion:", n1 - n2, "\n\n")

## Step 4: check_moody filter
cat("STEP 4: Apply check_moody filter [-0.2, 0.2]\n")
cat(paste(rep("-", 60), collapse=""), "\n")
cat("check_moody range in data: min=", round(min(df$check_moody, na.rm=T), 4),
    ", max=", round(max(df$check_moody, na.rm=T), 4), "\n")

# Show distribution
check_dist <- df %>%
  filter(!is.na(check_moody)) %>%
  mutate(range = case_when(
    check_moody < -0.2 ~ "< -0.2 (excluded)",
    check_moody >= -0.2 & check_moody <= 0.2 ~ "[-0.2, 0.2] KEPT",
    check_moody > 0.2 ~ "> 0.2 (excluded)"
  )) %>%
  count(range)
print(check_dist)

df <- df %>% filter(check_moody < 0.2 & check_moody > -0.2)
n3 <- nrow(df)
cat("\nAfter check_moody filter:", n3, "\n")
cat("Lost from check_moody filter:", n2 - n3, "\n\n")

## Step 5: Create period indicators
cat("STEP 5: Create post_detail (period indicators)\n")
cat(paste(rep("-", 60), collapse=""), "\n")
df <- df %>%
  mutate(
    post_detail = case_when(
      year %in% 1924:1926 ~ 1,
      year %in% 1927:1928 ~ 2,
      year %in% 1929:1933 ~ 3,
      year %in% 1934:1938 ~ 4,
      year %in% 1941:1943 ~ 5,
      TRUE ~ NA_real_
    )
  )
n4 <- nrow(df %>% filter(!is.na(post_detail)))
cat("After post_detail creation:", n4, "\n")
cat("Lost from post_detail filter:", n3 - n4, "\n\n")

## Step 6: Create lagged revenue
cat("STEP 6: Create lagged revenue (L_real_pc_rev_total_log)\n")
cat(paste(rep("-", 60), collapse=""), "\n")
df <- df %>%
  arrange(id_, year) %>%
  group_by(id_) %>%
  mutate(L_real_pc_rev_total_log = lag(real_pc_rev_total_log)) %>%
  ungroup()

n5_before <- nrow(df %>% filter(!is.na(post_detail)))
n5 <- nrow(df %>% filter(!is.na(post_detail), !is.na(L_real_pc_rev_total_log)))
cat("With lagged revenue:", n5, "\n")
cat("Lost from lag creation:", n5_before - n5, "\n\n")

## Step 7: Filter to complete cases for model
cat("STEP 7: Filter to complete cases (all controls)\n")
cat(paste(rep("-", 60), collapse=""), "\n")

df_model <- df %>%
  filter(!is.na(post_detail)) %>%
  filter(!is.na(real_pc_outlay)) %>%
  filter(!is.na(pop_30), !is.na(pop_20_30)) %>%
  filter(!is.na(real_pc_rev_total_log), !is.na(L_real_pc_rev_total_log)) %>%
  filter(!is.na(region_), !is.na(leverage))

n6 <- nrow(df_model)
cat("After all complete case filters:", n6, "\n")
cat("Lost from complete cases:", n5 - n6, "\n\n")

## Step 8: Poisson filter (real_pc_outlay > 0)
cat("STEP 8: Poisson filter (real_pc_outlay > 0)\n")
cat(paste(rep("-", 60), collapse=""), "\n")
n7_zeros <- sum(df_model$real_pc_outlay == 0, na.rm=T)
cat("Zeros in real_pc_outlay:", n7_zeros, "\n")

df_final <- df_model %>% filter(real_pc_outlay > 0)
n7 <- nrow(df_final)
cat("After removing zeros:", n7, "\n")
cat("Lost from zero filter:", n6 - n7, "\n\n")

## Summary
cat("\n")
cat(paste(rep("=", 70), collapse=""), "\n")
cat("SUMMARY: Observation Loss Tracking\n")
cat(paste(rep("=", 70), collapse=""), "\n\n")

summary_table <- data.frame(
  Step = c(
    "1. Raw data",
    "2. After leverage filter",
    "3. After year exclusion",
    "4. After check_moody filter",
    "5. After post_detail",
    "6. After lag creation",
    "7. After complete cases",
    "8. After zeros removed",
    "",
    "EXPECTED (Stata)",
    "DIFFERENCE"
  ),
  N = c(
    n0, n1, n2, n3, n4, n5, n6, n7,
    NA,
    3829,
    n7 - 3829
  ),
  Lost = c(
    NA,
    n0 - n1,
    n1 - n2,
    n2 - n3,
    n3 - n4,
    n4 - n5,
    n5 - n6,
    n6 - n7,
    NA, NA, NA
  )
)

print(summary_table, row.names = FALSE)

cat("\n")
cat(paste(rep("=", 70), collapse=""), "\n")
cat("YOUR FINAL N:", n7, "| EXPECTED N: 3829 | DIFFERENCE:", n7 - 3829, "\n")
cat(paste(rep("=", 70), collapse=""), "\n\n")

## Additional diagnostics
cat("ADDITIONAL CHECKS:\n")
cat(paste(rep("-", 60), collapse=""), "\n")
cat("1. Unique cities in final sample:", n_distinct(df_final$id_), "\n")
cat("2. Years in final sample:", paste(sort(unique(df_final$year)), collapse=", "), "\n")
cat("3. Observations per city (mean):", round(mean(table(df_final$id_)), 1), "\n\n")

# Check if it's a balanced panel
city_counts <- df_final %>% count(id_)
cat("4. Cities with observations:\n")
print(table(city_counts$n))

cat("\n=== INTERPRETATION ===\n")
if (abs(n7 - 3829) <= 10) {
  cat("✓ Your N is very close to Stata (within 10 obs). This is acceptable!\n")
} else if (n7 < 3829) {
  cat("✗ You're missing", 3829 - n7, "observations compared to Stata.\n")
  cat("  Most likely causes:\n")
  cat("  - Lag creation loses first observation per city\n")
  cat("  - Different handling of missing values in controls\n")
  cat("  - Region variable has more missing values than expected\n")
} else {
  cat("✗ You have", n7 - 3829, "extra observations compared to Stata.\n")
  cat("  Most likely causes:\n")
  cat("  - Missing a filter condition\n")
  cat("  - Different year exclusions needed\n")
}
