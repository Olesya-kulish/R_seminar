# Diagnostic Guide: Comparing R to Stata

## Table IV, Panel A: Key Diagnostic Points

### What We're Checking:
1. **check_moody variable range** - Stata filters to: `if check<0.2 & check>-0.2`
   - This removes outliers in the Moody leverage measure
   - Distribution should show most observations falling in -0.2 to 0.2 range
   - Expected N before this filter: ~4500
   - Expected N after this filter: ~3829

2. **Year exclusions** - Both Stata and R exclude 1939-1940
   - After this filter, should lose ~250-300 observations

3. **Zero outcomes** - Poisson models drop `real_pc_outlay = 0`
   - This costs us ~100-200 more observations
   - But we're still at 3748 (close to 3829!)

4. **Sample composition** 
   - Years in sample: 1924-1926, 1927-1928, 1929-1933, 1934-1938, 1941-1943
   - Missing: 1939, 1940 (excluded), 1921-1923 (before range), 1944+ (after range)
   - Should have 17 years total with data

---

## Table III, Panel A: Key Diagnostic Points

### Current Issue:
- Getting N=11,577 instead of expected N=10,903
- **Extra observations: 674**

### What We're Checking:
1. **Year 1939-1940 exclusion** 
   - Should be done ✓ (confirmed in code)
   - Losing ~300 obs

2. **Step-by-step loss**
   - After post_detail: Check that all 1924-1926, 1927-1928, etc. included
   - After outcome filter: How many `real_pc_maint_dep_total_log` missing?
   - After population filters: How many `pop_30` or `pop_20_30` missing?
   - After revenue filters: How many lag issues?

3. **Panel balance**
   - With years 1924-1926, 1927-1928, 1929-1933, 1934-1938, 1941-1943 = 17 years
   - If 641 cities: expect 641 × 17 = 10,897
   - We're getting 11,577 = extra 680 observations!
   - **This suggests we might have more cities OR some cities appear more than once per year**

---

## How to Interpret the Output

### When you run Table_IV_PanelA.r:
```
=== DIAGNOSTIC: check_moody variable ===
N observations before any filters: [should be ~19K]
check_moody range: [should be from negative to positive]
check_moody missing: [should be low, <100]

check_range              n
< -0.2              [?]
-0.2 to 0.2         [should be ~3829 or ~4200 depending on year filter]
> 0.2               [?]

N after year and check filters: [should be ~3829-3900]
```

### When you run Table_III_A.r:
```
=== DETAILED DIAGNOSTIC: Column 4 sample construction ===
After post_detail filter: [should be ~12,300]
After outcome filter: [should be ~12,300-12,500]
After population filters: [should be ~12,100-12,300]
After revenue filters: [should be ~11,000-11,500]
After leverage filter: [should be ~10,900-11,000, but getting 11,577]

Year distribution in complete sample:
[Should show all years 1924-1926, 1927-1928, 1929-1933, 1934-1938, 1941-1943]
[Each year should have ~640 cities approximately]

Number of cities and their observation counts:
[Each city should have exactly 17 observations if balanced]
```

---

## Next Steps After Running Diagnostics

### If Table IV N is still 3748 vs 3829 (81 observations short):
- Check if there's an implicit year filter in Stata we're missing
- Check if `check` should be `check_moody` (they might be different variables)
- Check if there are any other implicit filters in Stata code

### If Table III N is 11,577 vs 10,903 (674 observations extra):
- **Check if some cities have more than 1 observation per year** (duplicate records?)
- Check if years 1939-1940 were properly excluded
- Check if outcome variable has duplicates when multiple entries per city-year exist
- Compare Stata's `bysort id_: egen counter = count(year)` logic

---

## Files to Reference

- **Stata code**: Look at lines 434-499 in `replication-code-city.do`
  - Line 434: `if check<0.2 & check>-0.2` - This is the key filter
  - Look for any other implicit sample restrictions

- **Your R scripts**:
  - `scripts/Table_IV_PanelA.r` - Table IV diagnostics
  - `scripts/Table_III_A.r` - Table III diagnostics

- **Expected outputs** (from Stata):
  - Table IV: N=3829 (confirmed in paper)
  - Table III Column 4: N=10,903 (from your previous run expectations)
