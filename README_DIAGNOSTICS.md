# Stata Comparison Toolkit - Complete Setup

## Three Diagnostic Scripts Ready to Use

### 1. **check_vs_check_moody.r** (START HERE!)
**Purpose:** Identify if the issue is using the wrong variable

**Run in RStudio:**
```r
setwd("c:\\Users\\olesy\\OneDrive\\Dokumente\\uni\\R_Seminar\\R_seminar")
source("check_vs_check_moody.r")
```

**What it checks:**
- Does `check` variable exist (separate from `check_moody`)?
- Are they different values?
- If we use `check` instead of `check_moody`, do we get N=3829?

**Expected outcome:**
- Either: ✓✓✓ USING 'check' GIVES US THE RIGHT ANSWER (3829)!
- Or: Data showing they're different and how to fix it

---

### 2. **diagnostic_quick_check.r** (MAIN DIAGNOSTIC)
**Purpose:** Show you exactly where the observation discrepancies come from

**Run in RStudio:**
```r
setwd("c:\\Users\\olesy\\OneDrive\\Dokumente\\uni\\R_Seminar\\R_seminar")
source("diagnostic_quick_check.r")
```

**What it shows:**
- Table IV `check_moody` distribution (how many obs in range)
- Table IV step-by-step observation loss
- Table III step-by-step filtering
- **Number of cities in your sample** ← KEY FOR EXPLAINING EXTRA 674 OBS
- Balance check (is panel balanced?)

**Key outputs to note:**
```
TABLE IV EXPECTED N: 3829 | YOUR N: [?]
Difference: [?]

TABLE III EXPECTED N: 10903 | YOUR N: [?]
Difference: [?]
```

---

### 3. **HOW_TO_COMPARE_TO_STATA.md** (INTERPRETATION GUIDE)
**Purpose:** Explain what each diagnostic output means and how to fix it

**Contains:**
- Expected diagnostic output format
- How to interpret each section
- Troubleshooting guide for each discrepancy
- Next steps based on findings

---

## Quick Action Plan

### Step 1: Check Variables (5 minutes)
```r
source("check_vs_check_moody.r")
```
→ **If this finds the issue, update Table_IV_PanelA.r and you're done!**

### Step 2: Run Full Diagnostic (5 minutes)
```r
source("diagnostic_quick_check.r")
```
→ **Note the city count and year distribution**

### Step 3: Investigate Based on Findings
**If Table IV still doesn't match:**
- Read DIAGNOSTIC_GUIDE.md section on Table IV
- Check if there are other filters in Stata code
- Compare `check` vs `check_moody` results from Step 1

**If Table III has extra 674 obs:**
- Count the cities (should be 641 for N=10,903)
- If you have 681 cities, that's 40 extra → 40×17 = 680 extra obs
- Check Stata code for city-level restrictions

---

## Files Modified with Diagnostics

### Enhanced Scripts:
1. **scripts/Table_IV_PanelA.r**
   - Now shows `check_moody` distribution
   - Shows step-by-step observation loss
   - Diagnostic output when you run it

2. **scripts/Table_III_A.r**
   - Now shows city counts
   - Balance check (balanced vs unbalanced)
   - Year-by-year breakdown
   - Step-by-step filtering diagnostics

### New Diagnostic Scripts:
1. **diagnostic_quick_check.r** ← Main diagnostic, easiest to run
2. **check_vs_check_moody.r** ← Check the variable issue
3. **DIAGNOSTIC_GUIDE.md** ← Interpretation guide
4. **HOW_TO_COMPARE_TO_STATA.md** ← Complete walkthrough

---

## Expected Issues & Solutions

### Issue 1: Table IV N = 3748 vs 3829 (81 obs short)

**Likely Cause:** Using `check_moody` instead of `check`

**Solution:**
- Run `check_vs_check_moody.r`
- If it shows using `check` gives N=3829, update code:
  ```r
  # Change from:
  filter(check_moody < 0.2 & check_moody > -0.2)
  
  # To:
  filter(check < 0.2 & check > -0.2)
  ```

---

### Issue 2: Table III N = 11,577 vs 10,903 (674 extra)

**Likely Cause:** Too many cities in sample (681 vs expected 641)

**Why:** 
- Extra 40 cities × 17 years = 680 extra observations
- This matches your 674 discrepancy!

**Solution:**
1. Run `diagnostic_quick_check.r`
2. Check the "Unique cities in final sample" number
3. Look in Stata code for: `bysort id_: egen counter = count(year)`
   - This checks if cities have full 18-year panel
   - Cities without full data should be excluded

**Potential fix:**
```r
# Add to filtering pipeline:
# Only keep cities with 18 observations (1924-1943 minus 1939-1940)
df_complete <- df %>%
  # ... all existing filters ...
  group_by(id_) %>%
  filter(n() == 17) %>%  # Only cities with exactly 17 years
  ungroup()
```

---

## What to Do Now

1. **Open RStudio**
2. **Run these commands:**
   ```r
   setwd("c:\\Users\\olesy\\OneDrive\\Dokumente\\uni\\R_Seminar\\R_seminar")
   source("check_vs_check_moody.r")
   source("diagnostic_quick_check.r")
   ```
3. **Copy the output and share** - the numbers will tell us exactly what's wrong
4. **Use HOW_TO_COMPARE_TO_STATA.md** to interpret results
5. **Make fixes** based on findings

---

## Success Criteria

✓ Table IV N matches Stata exactly (or within 10 obs)
✓ Table III N matches Stata exactly (or within 10 obs)  
✓ Coefficients and SEs are identical to Stata
✓ All significance levels match

Once these match, your replication is validated!

---

## Still Stuck?

If diagnostics don't clarify the issue:

1. **Check the Stata code more carefully**
   - Look for `if` conditions beyond what's in Table IV/III code
   - Check lines around 434, 280-300 (Table II), 170-200 (Table III)

2. **Verify variable names**
   - All leverage measures spelled correctly?
   - Outcome variables match exactly?
   - Control variables exist?

3. **Cross-check with paper**
   - What N values does the paper report?
   - Are they footnoted with sample restrictions?
   - Are there appendix tables with different samples?

4. **Contact original author**
   - Stata replication packages often have issues
   - Authors usually respond to replication questions
   - Worth asking about variable definitions

Good luck! The diagnostics should make this much clearer.
