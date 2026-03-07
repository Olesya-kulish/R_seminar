library(haven)
library(dplyr)
library(fixest)

df_city <- read_dta('data/replication-data-city.dta')

df <- df_city %>%
  mutate(leverage = debt_to_rev29_lev_moody_std) %>%
  filter(!(year %in% c(1939, 1940))) %>%
  filter(check_moody < 0.2 & check_moody > -0.2)

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

df <- df %>%
  arrange(id_, year) %>%
  group_by(id_) %>%
  mutate(L_real_pc_rev_total_log = lag(real_pc_rev_total_log)) %>%
  ungroup()

df_panel_a <- df %>%
  filter(!is.na(post_detail)) %>%
  filter(!is.na(real_pc_outlay)) %>%
  filter(!is.na(pop_30), !is.na(pop_20_30)) %>%
  filter(!is.na(real_pc_rev_total_log), !is.na(L_real_pc_rev_total_log)) %>%
  filter(!is.na(region_), !is.na(leverage))

cat("Total observations after filters:", nrow(df_panel_a), "\n")
cat("Number of unique cities:", n_distinct(df_panel_a$id_), "\n")

# Check observations per city
obs_per_city <- df_panel_a %>%
  group_by(id_) %>%
  summarize(n_obs = n()) %>%
  arrange(n_obs)

cat("\nDistribution of observations per city:\n")
print(table(obs_per_city$n_obs))

# Cities with only 1 observation (singletons)
singletons <- obs_per_city %>% filter(n_obs == 1)
cat("\nNumber of singleton cities:", nrow(singletons), "\n")

# Check if dropping singletons gets us closer to 3,829
cat("Observations after dropping singletons:", nrow(df_panel_a) - nrow(singletons), "\n")

# Try with fepois to see what it does
model_pois <- fepois(
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

cat("\nPoisson model N:", nobs(model_pois), "\n")

# Check which cities were dropped
cities_in_model <- unique(model_pois$obs_selection$obsRemoved == FALSE)
cat("Cities dropped by model:", sum(is.na(model_pois$fitted.values)), "\n")
