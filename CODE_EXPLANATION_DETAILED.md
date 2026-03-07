# Table IV Column 3 - Complete Code Explanation

## Overview
This script replicates **Table IV Column 3** from the paper using the **friend-style approach**. It tests how **debt-to-revenue leverage in 1929** affected city spending during the Great Depression.

Two separate econometric models:
- **Panel A**: OLS Fixed Effects on logged maintenance spending
- **Panel B**: Poisson PPML on count of capital projects

---

## 1. Sample Restriction: The Moody's Filter

```r
df0 <- df %>%
  dplyr::filter(check_moody < 0.2, check_moody > -0.2)
```

**What it does:**
- Keeps only observations where `check_moody` is between -0.2 and +0.2
- `check_moody` is a data quality measure for Moody's ratings

**Why it matters:**
- Moody's dataset has outliers (cities with extreme values)
- These might be data entry errors or cities with poor data quality
- Restricting to ±0.2 keeps "clean" Moody's observations
- **Result:** Your N drops from ~6,800 to ~3,829

**Real-world analogy:** Like filtering a survey to keep only respondents who passed basic quality checks

---

## 2. Specify the Treatment Variable

```r
a_name <- "debt_to_rev29_lev"
testvar <- paste0(a_name, "_moody_std")  # = "debt_to_rev29_lev_moody_std"
```

**What it does:**
- Creates the variable name for the leverage measure
- `debt_to_rev29_lev_moody_std` = **standardized debt-to-revenue ratio in 1929** (Moody's sample)

**Interpretation:**
- Higher value = city had more debt relative to revenue before the crash
- Already standardized (mean=0, sd=1) so coefficients are **per SD increase**
- Example: coefficient -0.09 means cities with 1 SD higher leverage cut maintenance 9% more

**Why 1929?**
- This is before the Great Depression crisis hit
- Captures structural financial vulnerability that pre-dated the shock
- Creates exogenous variation: cities couldn't predict the crash

---

## 3. Panel A: FE-OLS on Maintenance Spending

### The Model Formula

```r
"real_pc_maint_dep_total_log ~ 
  i(post_detail, ref = 2) * testvar +      # DiD: periods × leverage (periods 1,3,4,5)
  i(year, ref = 1928) +                    # Year fixed effects
  i(year, pop_30, ref = 1928) +            # 1930 population × year interactions
  i(year, pop_20_30, ref = 1928) +         # 1920-30 population change × year
  real_pc_rev_total_log +                  # Current revenue (control)
  l(real_pc_rev_total_log, 1) +            # Lagged revenue (spending inertia)
  i(year, region_) | id_"                  # Region×year + city FE
```

**Left-hand side (outcome):**
- `real_pc_maint_dep_total_log` = logged per-capita maintenance spending
- Why log? Spending is right-skewed; log normalizes it

**Right-hand side (explanatory):**

1. **`i(post_detail, ref = 2) * testvar`** — The key DiD interaction
   - `post_detail` = 5 time periods
     - Period 1: 1924-26 (pre-crisis)
     - Period 2: 1927-28 (reference = base for comparison)
     - Period 3: 1929-33 (early crisis)
     - Period 4: 1934-38 (recovery)
     - Period 5: 1941-43 (war/late)
   - Interacted with `testvar` (leverage)
   - **Estimates:** "Did high-leverage cities cut maintenance MORE in each period vs 1927-28?"

2. **`i(year, ref = 1928)`** — Year fixed effects
   - Captures time-invariant shocks (e.g., national recessions)
   - Reference year = 1928

3. **`i(year, pop_30)` and `i(year, pop_20_30)`** — Population interactions
   - City growth may affect spending decisions
   - These interactions allow growth effect to differ by year
   - Control for confounding: "cities that grew might have different leverage patterns"

4. **`real_pc_rev_total_log + l(real_pc_rev_total_log, 1)`** — Revenue controls
   - Current revenue: cities with more revenue can spend more
   - Lagged revenue: spending has inertia (past budget influences current spending)
   - **THE PROBLEM:** Lagged revenue breaks around 1939-1940 gap → wrong coefficient for 1941-43

5. **`i(year, region_)`** — Region × year interactions
   - Regional shocks (e.g., drought in Midwest) differ by year
   - Controls for regional variation

6. **`| id_`** — City fixed effects
   - Controls for permanent city characteristics (geography, governance, etc.)
   - DiD exploits within-city variation over time

### The Estimation

```r
mA <- fixest::feols(
  fml = make_fml_A(testvar),
  data = df0,
  vcov = ~ id_,           # Cluster SEs by city
  panel.id = ~ id_ + year # Tells fixest about panel structure for lag operator
)
```

**What it does:**
- Runs fixed effects OLS regression
- `vcov = ~ id_` clusters standard errors by city (cities are non-independent)
- `panel.id` declares panel structure so `l()` lag operator knows city identities

**Interpretation of a coefficient:**
- Example: 1929-33 coefficient = -0.023
- **Meaning:** Among high-leverage cities, maintenance spending was 2.3% LOWER during 1929-33 crisis vs 1927-28, compared to low-leverage cities
- This is the **Difference-in-Differences** estimand

---

## 4. Panel B: PPML on Capital Outlay

### Why Different Estimator?

```r
"real_pc_outlay ~ ... | id_ + year"  # Note: TWO fixed effects, not one!
```

**The outcome `real_pc_outlay` is special:**
- Count data (number of capital projects: 0, 1, 2, 3, ...)
- Many zeros (cities doing no capital projects)
- **Problem with OLS:** Can predict negative counts (impossible!)
- **Solution:** Use Poisson PPML instead

### The Model

```r
mB <- fixest::fepois(                    # Poisson, not feols!
  fml = make_fml_B(testvar),
  data = df0,
  vcov = ~ id_,
  panel.id = ~ id_ + year
)
```

**Key differences from Panel A:**
- `fepois` instead of `feols` (Poisson instead of OLS)
- Fixed effects specification: `| id_ + year` (city AND year)
  - Panel A: only `| id_` (city)
  - Why? PPML needs year FE inside the model; OLS can handle it via interactions

**Interpretation:**
- PPML coefficients are elasticities, not percentage points
- Example: 1934-38 coefficient = -0.346
- **Meaning:** High-leverage cities reduced capital projects by ~35% during recovery vs 1927-28

**Why use PPML?**
- Correctly handles zeros in count data
- Preserves exposure (all cities contribute even if count=0)
- Gives different answer than OLS (PPML more efficient for counts)

---

## 5. Extracting and Formatting Results

```r
extract_4_inter <- function(m, testvar) {
  ct <- fixest::coeftable(m)
  rn <- rownames(ct)
  # Find coefficients matching pattern: "testvar:post_detail::(1|3|4|5)"
  pat <- paste0("^", testvar, ":post_detail::(1|3|4|5)$")
  idx <- stringr::str_detect(rn, pat)
  ct2 <- ct[idx, , drop = FALSE]
  
  # Extract estimates, SEs, p-values
  est <- ct2[, "Estimate"]
  se <- ct2[, "Std. Error"]
  p <- ct2[, "Pr(>|t|)"]  # or Pr(>|z|) for PPML
  st <- pstars(p)         # Add *, **, *** for significance
  
  list(
    est = sprintf("%.2f%s", est, st),   # e.g., "-0.09*"
    se = sprintf("(%.2f)", se)          # e.g., "(0.02)"
  )
}
```

**What it does:**
1. Gets all model coefficients
2. Finds only the 4 interaction terms (periods 1, 3, 4, 5)
3. Extracts estimates, standard errors, p-values
4. Adds significance stars based on p-values
5. Formats as strings: `-0.09*` with `(0.02)` below

**Why 4 periods?**
- Reference period (2 = 1927-28) is omitted
- So we see: period 1 vs ref, period 3 vs ref, period 4 vs ref, period 5 vs ref

---

## 6. The DiD Logic

### Difference-in-Differences Intuition

**Treat:** High-leverage cities (top 50% by debt-to-revenue)  
**Control:** Low-leverage cities (bottom 50%)  
**Before:** 1927-1928 (pre-crisis)  
**After:** 1929-33, 1934-38, 1941-43 (post-crisis periods)

```
                Before      After       Difference
High Leverage   Y_H^B       Y_H^A       Y_H^A - Y_H^B
Low Leverage    Y_L^B       Y_L^A       Y_L^A - Y_L^B

DiD = (Y_H^A - Y_H^B) - (Y_L^A - Y_L^B)
```

**Interpretation:** Did high-leverage cities suffer MORE spending cuts than low-leverage cities?

---

## 7. Building Output Tables

```r
# Create row with coefficients and SEs
rowA <- data.frame(term = rep(term_show, each = 2), stringsAsFactors = FALSE)
rowA$m3 <- as.vector(rbind(dA$est, dA$se))
rowA$term[seq(2, nrow(rowA), by = 2)] <- ""

# Add goodness-of-fit statistics
gofA <- data.frame(
  term = c("City FE", "Year FE", "1930 Pop x Year", ..., "R-sq (within)", "N", "Mean(y)", "SD(y)"),
  m3 = c("Y", "Y", "Y", ..., sprintf("%.2f", safe_wr2(mA)), ...)
)

# Combine into final table
tabA <- dplyr::bind_rows(rowA, gofA)
```

**What it creates:**
```
                                    Column 3
Moody leverage x 1924-1926         -0.01
                                  (0.02)
Moody leverage x 1929-1933         -0.02**
                                  (0.01)
...
City FE                             Y
Year FE                             Y
R-sq (within)                       0.65
N                                   3829
Mean(y)                             4.07
```

---

## 8. Why The 1941-43 Coefficient is Wrong (Summary)

**The lag creates a gap problem:**

```
Panel structure: 1924, 1925, ..., 1938, [GAP: 1939-1940], 1941, 1942, 1943

When fitting 1941:
- Needs L1.real_pc_rev_total_log (lagged revenue)
- Should be 1940 value
- But 1940 is MISSING!

Stata's xtset: Correctly recognizes gap, sets lag = NA for 1941
R fixest: May use 1938 instead (wrong value) or drop 1941

Result: 1941-43 coefficient is biased (wrong control variable or dropped obs)
```

This is why Panel B's 1941-43 is -0.18 instead of -0.09 (off by 100%).

---

## Key Takeaways for Your Lecture

1. **DiD Design:** Exploit pre-crisis leverage variation to test whether financial distress caused spending cuts
2. **Two Estimators:** OLS for continuous outcomes, PPML for counts
3. **Controls Matter:** Population growth + revenue + region effects all included to isolate the treatment effect
4. **Gap Problem:** Panel data with missing years creates lag ambiguity across software packages
5. **Close Fit:** The fact that 1924-1938 coefficients match shows you got the spec right; only the post-gap period has issues

Your replication successfully demonstrates the economic mechanism: **high-leverage cities cut both maintenance AND capital spending during the Great Depression.**
