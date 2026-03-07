# How to Compare Your R Results to Stata

## Quick Start: Run These Diagnostics

### In RStudio Console:
```r
setwd("c:\\Users\\olesy\\OneDrive\\Dokumente\\uni\\R_Seminar\\R_seminar")
source("diagnostic_quick_check.r")
```

This will show:
1. **Table IV check_moody distribution** - How many observations fall in/out of range
2. **Table III year-by-year breakdown** - Where the extra 674 observations are hiding
3. **Balance check** - Whether your panel is truly balanced

---

## What Each Diagnostic Tells You

### TABLE IV DIAGNOSTICS

**Expected output structure:**
```
TABLE IV, PANEL A: DIAGNOSTIC CHECK
====================================================================

STEP 1: Examining check_moody variable
--------------------------------------------
N total: ~19,000
check_moody: min= [negative], max= [positive]
check_moody missing: < 100

range                        count    pct
< -0.2                       XXXX     XX%
IN RANGE [-0.2, 0.2]         3829     XX% ← THIS IS WHAT WE WANT
> 0.2                        XXXX     XX%

STEP 2: Impact of year filters
--------------------------------------------
N with valid check_moody: ~19,000
N after excluding 1939-1940: ~18,700
N after check filter [-0.2, 0.2]: ~3900

STEP 3: Impact of real_pc_outlay > 0 filter
--------------------------------------------
N with real_pc_outlay: ~3900
N with real_pc_outlay > 0: 3748

====================================================================
TABLE IV EXPECTED N: 3829 | YOUR N: 3748
Difference: -81
====================================================================
```

**Key insight:** The -81 difference suggests something else is being filtered in Stata that we're not catching. Possible causes:
1. The `check` variable might be different from `check_moody`
2. There might be an implicit year restriction we're missing
3. Some leverage values might be invalid (NaN, Inf, etc.)

---

### TABLE III DIAGNOSTICS

**Expected output structure:**
```
TABLE III, PANEL A: DIAGNOSTIC CHECK
====================================================================

STEP 1: After year exclusion
--------------------------------------------
N: ~12,350
Unique cities: 641
Unique years: 1924, 1925, 1926, 1927, 1928, 1929, ..., 1938, 1941, 1942, 1943

STEP 2: After post_detail creation
--------------------------------------------
N with post_detail: ~12,350

STEP 3: Progressively add filters
--------------------------------------------
After post_detail: 12350
After outcome variable: 12305 (lost 45)
After population: 12100 (lost 205)
After revenue: 11800 (lost 300)
After leverage: 11577 (lost 223)

STEP 4: Balance check
--------------------------------------------
Unique cities in final sample: 681
Years per city (expected if balanced): 17
Expected N if balanced: 11,577
Actual N: 11,577
Excess observations: 0

✓ BALANCED PANEL

Year distribution in final sample:
year    n
1924   681
1925   681
1926   681
1927   681
1928   681
1929   681
1930   681
1931   681
1932   681
1933   681
1934   681
1935   681
1936   681
1937   681
1938   681
1941   681
1942   681
1943   681

====================================================================
TABLE III EXPECTED N: 10903 | YOUR N: 11,577
Difference: 674
====================================================================
```

**Key insight:** The 674 excess observations likely comes from TWO sources:
1. **Extra cities:** You have 681 cities, but Stata might have 641 (difference of 40)
   - 40 cities × 17 years = 680 extra observations ✓
2. **Or:** Different sample restriction we're not applying

---

## How to Diagnose the Extra 674 Observations

### Check 1: Number of Cities
Compare your R sample to Stata:
- Your R sample: **681 cities** (shown in diagnostics as "Unique cities: 681")
- Stata sample: Should be **641 cities** (if 10,903 ÷ 17 = 641)

**Action:** Check the `data/replication-code-city.do` file for any city-level restrictions (e.g., minimum population, must have data in all years, etc.)

### Check 2: Verify Stata's Sample Size Claim
Look at Table III Panel A in your original output or paper:
- Does it say N=10,903 or something different?
- Are all columns in Table III the same N, or do they vary?

### Check 3: Check for Missing Values in Original Data
```r
# In RStudio, check your raw data
df_raw <- read_dta('data/replication-data-city.dta')

# How many unique cities?
length(unique(df_raw$id_))

# Are there cities with more than 18 observations (18 years: 1924-1943 minus 1939-1940)?
df_raw %>% count(id_) %>% filter(n > 18) %>% nrow()
```

---

## If check_moody Filter is Wrong

The Stata code line 434 says:
```stata
if check<0.2 & check>-0.2
```

**Not** `check_moody`, but `check`. These might be different variables!

Check your data:
```r
df_raw <- read_dta('data/replication-data-city.dta')

# Does 'check' exist?
"check" %in% names(df_raw)  # Should return TRUE

# What's the difference between check and check_moody?
df_raw %>% select(check, check_moody) %>% head(20)
```

If `check` is different from `check_moody`, update your R code:
```r
# Change from:
filter(check_moody < 0.2 & check_moody > -0.2)

# To:
filter(check < 0.2 & check > -0.2)
```

---

## Files You've Created

### Main Diagnostic Files:
1. **diagnostic_quick_check.r** ← Run this first!
   - Quick visual output of where discrepancies are
   - Can run line-by-line in RStudio console

2. **Table_IV_PanelA.r** (enhanced)
   - Now includes `check_moody` distribution diagnostic
   - Shows step-by-step observation loss

3. **Table_III_A.r** (enhanced)
   - Now shows city count and balance check
   - Shows which filter loses how many observations

4. **DIAGNOSTIC_GUIDE.md**
   - Explanation of what each diagnostic means
   - Interpretation guide

### Output Files:
- output/table_IV_panelA_all_measures.csv
- output/table_III_A_cols_1_4.csv
- output/summary_stats_city1.csv
- output/table_II_cols_1_2_5.csv

---

## Validation Checklist

After running `diagnostic_quick_check.r`, check:

- [ ] Table IV N: Is it close to 3829? (acceptable: 3750-3850)
- [ ] Table IV check_moody: Most obs in range [-0.2, 0.2]? (should be ~70%)
- [ ] Table III balance: Does it say "BALANCED PANEL"?
- [ ] Table III cities: Note the number (681? 641? something else?)
- [ ] Table III years: All 17 years present (1924-1943 minus 1939-1940)?

---

## Questions to Answer About Stata Code

When you have the Stata output available, check:

1. **Does Stata's Table IV show N=3829 or something else?**
2. **Does Stata's Table III show N=10,903 or something different?**
3. **In Stata do file line 434, is it `check<0.2` or `check_moody<0.2`?**
4. **Are there any city-level restrictions (e.g., in replication-data-city.dta)?**
5. **Do some cities have data for all 18 years (1924-1943 except 1939-1940) or do some drop out?**

---

## Next Steps

1. **Run diagnostic_quick_check.r** and copy the output
2. **Share the output** - it will show exactly where the N discrepancies arise
3. **Check if `check` != `check_moody`** - this is likely the culprit for Table IV
4. **Count cities in raw data** - this will explain the 674 extra obs in Table III
5. **Cross-reference with Stata** - confirm expected N values from the paper or Stata output files

Good luck! The diagnostics should give us clear answers about what's different.
