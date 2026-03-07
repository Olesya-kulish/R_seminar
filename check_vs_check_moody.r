# Check if 'check' is different from 'check_moody'
# Run this in RStudio console

library(haven)
library(dplyr)

df <- read_dta('data/replication-data-city.dta')

cat("\n=== CHECKING check vs check_moody ===\n\n")

cat("1. Do both variables exist?\n")
cat("   check exists:", "check" %in% names(df), "\n")
cat("   check_moody exists:", "check_moody" %in% names(df), "\n\n")

if ("check" %in% names(df) & "check_moody" %in% names(df)) {
  cat("2. Summary statistics for both:\n\n")
  
  cat("   check:\n")
  cat("   - Min:", round(min(df$check, na.rm=T), 4), "\n")
  cat("   - Max:", round(max(df$check, na.rm=T), 4), "\n")
  cat("   - Missing:", sum(is.na(df$check)), "\n\n")
  
  cat("   check_moody:\n")
  cat("   - Min:", round(min(df$check_moody, na.rm=T), 4), "\n")
  cat("   - Max:", round(max(df$check_moody, na.rm=T), 4), "\n")
  cat("   - Missing:", sum(is.na(df$check_moody)), "\n\n")
  
  cat("3. Are they identical?\n")
  identical_check <- all(df$check == df$check_moody, na.rm=T)
  cat("   Identical:", identical_check, "\n\n")
  
  cat("4. Sample of first 20 rows:\n\n")
  sample_data <- df %>%
    select(id_, year, check, check_moody) %>%
    slice(1:20)
  print(sample_data)
  
  cat("\n5. Count of obs in each range for 'check':\n")
  check_range <- df %>%
    filter(!is.na(check)) %>%
    mutate(range = case_when(
      check < -0.2 ~ "< -0.2",
      check >= -0.2 & check <= 0.2 ~ "-0.2 to 0.2 [STATA RANGE]",
      check > 0.2 ~ "> 0.2"
    )) %>%
    group_by(range) %>%
    summarise(count = n(), pct = round(100*n()/nrow(.), 1))
  print(check_range)
  
  cat("\n6. If using 'check' instead of 'check_moody', what happens to Table IV N?\n")
  df_test <- df %>%
    filter(!(year %in% c(1939, 1940))) %>%
    filter(check < 0.2 & check > -0.2) %>%
    filter(!is.na(real_pc_outlay)) %>%
    filter(real_pc_outlay > 0)
  cat("   N with 'check' filter:", nrow(df_test), "\n")
  
  df_test2 <- df %>%
    filter(!(year %in% c(1939, 1940))) %>%
    filter(check_moody < 0.2 & check_moody > -0.2) %>%
    filter(!is.na(real_pc_outlay)) %>%
    filter(real_pc_outlay > 0)
  cat("   N with 'check_moody' filter:", nrow(df_test2), "\n")
  
  if (nrow(df_test) == 3829) {
    cat("\n   ✓✓✓ USING 'check' GIVES US THE RIGHT ANSWER (3829)! ✓✓✓\n")
  } else if (nrow(df_test2) == 3829) {
    cat("\n   ✓✓✓ USING 'check_moody' GIVES US THE RIGHT ANSWER (3829)! ✓✓✓\n")
  } else {
    cat("\n   Neither gives exactly 3829. Continue investigation...\n")
  }

} else {
  cat("ERROR: Cannot find one or both variables in the data!\n")
  cat("Variables in data:", paste(names(df), collapse=", "), "\n")
}
