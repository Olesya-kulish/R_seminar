# Replication package (R): Public Goods Under Financial Distress

This project reproduces the required tables from the original replication package using R.

**Author:** Olesya Kulish (R Seminar replication project)  
**Original paper:** "Public Goods Under Financial Distress" by Pawel Janas

---

## 1) Requirements

- **R** (tested on R 4.x)
- **Original data files:**
  - [data/replication-data-city.dta](data/replication-data-city.dta)
  - [data/replication-data-micro.dta](data/replication-data-micro.dta)
- **R packages:** `haven`, `dplyr`, `fixest`, `tibble`, `purrr`, `flextable`

Install packages once:

```r
install.packages(c("haven", "dplyr", "fixest", "tibble", "purrr", "flextable"))
```

---

## 2) How to run (ONE COMMAND)

From R or RStudio, set working directory to the project root and run:

```r
source("scripts/run_all_tables_with_log.r")
```

**What this does:**

1. Loads the original `.dta` replication files first (as required)
2. Runs all table scripts automatically
3. Writes a complete execution log using `sink()` to [output/run_log.txt](output/run_log.txt)
4. Writes per-script run status to [output/run_status.csv](output/run_status.csv)
5. Generates automated tables (CSV + PNG) in [output/](output)

**No manual intervention needed. All tables are self-explanatory and publication-ready.**

---

## 3) Individual scripts (optional)

You can also run scripts individually if needed:

- [scripts/Table_1.r](scripts/Table_1.r) → Table 1 (Panels A and C summary tables)
- [scripts/Table_II.r](scripts/Table_II.r) → Table II (Columns 1, 2, 5)
- [scripts/Table_III_A.r](scripts/Table_III_A.r) → Table III, Panel A (Columns 1, 4)
- [scripts/Table_IV_PanelAB.r](scripts/Table_IV_PanelAB.r) → Table IV, Column 3 (Panels A and B)

All scripts are fully annotated with inline comments explaining:
- Variable definitions
- Model specifications
- Fixed effects and clustering
- Output generation

---

## 4) Main output files

All outputs are saved to [output/](output):

**Summary Statistics:**
- [output/summary_stats_city1.csv](output/summary_stats_city1.csv) + .png
- [output/summary_stats_city_panelC.csv](output/summary_stats_city_panelC.csv) + .png

**Regression Tables:**
- [output/table_II_cols_1_2_5.csv](output/table_II_cols_1_2_5.csv) + .png
- [output/table_III_A_cols_1_4.csv](output/table_III_A_cols_1_4.csv) + .png
- [output/table_IV_both_panels_col3.csv](output/table_IV_both_panels_col3.csv) + .png + .tex

**Execution Logs:**
- [output/run_log.txt](output/run_log.txt) — Full `sink()` log with all console output
- [output/run_status.csv](output/run_status.csv) — Success/failure status by script

---

## 5) Requirements compliance checklist

**Code starts by loading original data** (`data/*.dta` files loaded first)  
**Code is annotated** (all scripts have self-explanatory inline comments)  
**README file included** (this document explains usage)  
**Automated tables produced** (CSV + PNG formats)  
**Log file included** ([output/run_log.txt](output/run_log.txt) via `sink()`)

---

## 6) Replication notes

**Table 1 (Panels A & C):**  FULLY CORRECT
  - Summary statistics replicated accurately
  - All 27 variables (Panel A) and 17 variables (Panel C) match expected values

**Table II:** Regression coefficients computed (script runs without error)

**Table III, Panel A:**  UPDATED / FIXED SPECIFICATION
  - Original script now uses the Stata-aligned setup (`test = bonds_to_assess29_lev_std`)
  - Uses the original `post_detail` variable from the data
  - Uses panel lag `l(real_pc_rev_total_log, 1)` with `panel.id = ~ id_ + year`
  - Outputs were regenerated with the updated specification

**Table IV, Column 3:**  INCORRECT
  - Panel A (Poisson): N=3,748 vs Stata N=3,829 (difference of 81 obs, 2.1%)
  - Panel B (OLS): N is same as in the original, but coefficients have slight differences
  - Key coefficients do not match Stata to expected precision
  - Replication does not change general insights

All models use:
- City and year fixed effects as specified
- Standard errors clustered at city level
- Standardized variables for interpretation

---

**For any questions, see [FINAL_PACKAGE_SUMMARY.txt](FINAL_PACKAGE_SUMMARY.txt) for additional details.**

