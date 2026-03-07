# Table III Panel A Replication Discrepancies

## Current Differences from Stata Original

**Column 4 Discrepancies:**
- **N**: 11,577 (R) vs. expected Stata value
- **R² (within)**: 0.57 (R) vs. expected Stata value  
- **Leverage × 1941-1943**: -0.03 (R) vs. expected Stata value
- **Mean(y)**: Missing in Column 4 (should be computed from final sample)

---

## Potential Causes of Discrepancies

### 1. **Interaction Term Handling**
**Issue**: `i(year, pop_30, ref=1928)` in fixest may drop observations differently than Stata's `c.pop_30##i.year`

**Technical Detail:**
- Stata: Drops obs if `pop_30` is missing OR if year is missing
- R fixest: Same behavior, but reference year handling may differ
- Both require non-missing values in BOTH components of interaction

**Evidence**: If some years have missing `pop_30` values, entire observations dropped

---

### 2. **Lagged Variable Construction**
**Issue**: Manual lag creation in R vs. Stata's built-in `L1.` operator

**Current R Implementation:**
```r
df <- df %>%
  arrange(id_, year) %>%
  group_by(id_) %>%
  mutate(L_real_pc_rev_total_log = lag(real_pc_rev_total_log)) %>%
  ungroup()
```

**Stata Implementation:**
```stata
xtreg ... L1.real_pc_rev_total_log
```

**Potential Issue**: 
- First year (1924) for each city: R creates NA, Stata might handle differently
- Cities with gaps in years: lag calculation may differ
- Panel structure declaration: Stata uses `xtset id_ year` which enforces strict panel rules

---

### 3. **Sample Restrictions Not Matched**
**Issue**: Stata's `xtreg, fe` has implicit sample restrictions not replicated in R

**Stata Implicit Restrictions:**
- Drops cities (groups) with no within-group variation in outcome
- Requires at least 2 time periods per group for FE estimation
- Automatically drops singleton observations
- May enforce balanced panel assumptions

**R fixest Behavior:**
- Also drops singletons automatically
- Handles within-variation, but algorithm may differ slightly
- More flexible with unbalanced panels

**Attempted Fix:**
```r
df_complete <- df_complete %>%
  group_by(id_) %>%
  filter(n() >= 2) %>%
  filter(sd(real_pc_maint_dep_total_log, na.rm = TRUE) > 0) %>%
  ungroup()
```

---

### 4. **Reference Year (1927-1928) Treatment**
**Issue**: Period 2 (1927-1928) is the reference for `post_detail`

**Concern**: 
- If 1927-1928 observations have different missing data patterns
- Interaction with year=1928 as reference creates complex dropout patterns
- Two reference levels (period 2 AND year 1928) may interact unexpectedly

---

### 5. **Clustering and Standard Errors**
**Issue**: While coefficients should match, different sample sizes affect SEs

**Current Implementation:**
- R: `cluster = ~ id_` (correct)
- Stata: `c(id_)` (equivalent)

**Impact**: If N differs, SEs will differ even if coefficients similar

---

### 6. **Missing Data in `bonds_to_assess29_lev_std`**
**Issue**: Using pre-computed standardized variable from Stata dataset

**Potential Problem:**
- Stata may have created this variable with specific sample restrictions
- R using it "as-is" without knowing original sample used for standardization
- Different handling of missings during standardization phase

**Alternative Approach Not Tried:**
```r
# Recompute standardization from scratch
leverage <- (bonds_to_assess29_lev - mean(bonds_to_assess29_lev, na.rm=TRUE)) / 
            sd(bonds_to_assess29_lev, na.rm=TRUE)
```

---

## Attempts Made to Fix

### ✓ **1. Correctly Excluded Years 1939-1940**
```r
filter(!(year %in% c(1939, 1940)))
```
Matches Stata's sample restriction (17-year panel from 1924-1943 excluding 1939-40)

---

### ✓ **2. Matched Period Indicators**
```r
post_detail = case_when(
  year %in% 1924:1926 ~ 1,
  year %in% 1927:1928 ~ 2,  # reference
  year %in% 1929:1933 ~ 3,
  year %in% 1934:1938 ~ 4,
  year %in% 1941:1943 ~ 5
)
```
Exact match to Stata's `ib2.post_detail`

---

### ✓ **3. Created Lagged Revenue**
```r
L_real_pc_rev_total_log = lag(real_pc_rev_total_log)
```
After sorting by `id_` and `year` within groups

---

### ✓ **4. Matched Model Specification**
Column 4 includes:
- City fixed effects (`| id_`)
- Year fixed effects (`i(year, ref=1928)`)
- Population × Year (`i(year, pop_30)` and `i(year, pop_20_30)`)
- Revenue controls (current and lagged)
- Cluster by city (`cluster = ~ id_`)

---

### ✓ **5. Explicit Missing Data Filtering**
```r
filter(!is.na(post_detail),
       !is.na(real_pc_maint_dep_total_log),
       !is.na(pop_30), !is.na(pop_20_30),
       !is.na(real_pc_rev_total_log), !is.na(L_real_pc_rev_total_log),
       !is.na(leverage))
```

---

### ✓ **6. Added Comprehensive Diagnostics**
Track sample size at each filtering step to identify where observations are lost

---

### ⚠️ **7. Attempted Stata xtreg Restrictions**
```r
group_by(id_) %>%
filter(n() >= 2) %>%
filter(sd(real_pc_maint_dep_total_log, na.rm = TRUE) > 0)
```
May be redundant (fixest already handles this) but ensures explicit matching

---

## What Still Needs Investigation

### 1. **Exact Sample Used in Stata**
- Run Stata code with diagnostics: `tab year if e(sample)`
- Export Stata's final regression sample to compare row-by-row with R

### 2. **Interaction Term Dropout Analysis**
- Check which specific observations are dropped when fixest processes interactions
- Compare to Stata's treatment of same observations

### 3. **Panel Balance**
- Verify whether Stata assumes balanced panel for Column 4
- Check if unbalanced cities are causing coefficient differences

### 4. **Re-standardize Leverage Variable**
- Compute `bonds_to_assess29_lev_std` from scratch in R
- Compare to Stata's pre-computed version

---

## Recommendations for Lecture Presentation

### Frame as Learning Opportunity:
1. **"Replication is hard"** - even with published code, small implementation differences matter
2. **"Black box differences"** - Stata xtreg vs. R fixest may have subtle algorithmic differences
3. **"Sample construction matters"** - most discrepancies arise from how missing data and samples are handled
4. **"Diagnostics are crucial"** - added step-by-step tracking to identify issues

### Emphasize What Went Right:
- Successfully loaded Stata .dta files in R (haven package)
- Correctly specified fixed effects models in fixest
- Matched Stata's interaction syntax and reference levels
- Generated publication-quality output tables (PNG, CSV)

### Honest About Limitations:
- Final N differs by ~X observations (need to quantify exact difference)
- R² differs slightly (0.57 vs. expected)
- 1941-43 coefficient differs (possibly due to sample composition in that period)
- Without access to Stata, cannot definitively verify root cause

### Next Steps Mentioned:
- Would need to run original Stata code with diagnostics
- Could export Stata's final sample and compare row-by-row
- Alternative: Contact original authors for clarification on exact sample restrictions
