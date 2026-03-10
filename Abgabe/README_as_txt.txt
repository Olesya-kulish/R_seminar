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


---

## 3) Individual scripts (optional)

You can also run scripts individually if needed:

- [scripts/Table_1.r](scripts/Table_1.r) -> Table 1 (Panels A and C summary tables)
- [scripts/Table_II.r](scripts/Table_II.r) -> Table II (Columns 1, 2, 5)
- [scripts/Table_III_A.r](scripts/Table_III_A.r) -> Table III, Panel A (Columns 1, 4)
- [scripts/Table_IV_col3.r](scripts/Table_IV_col3.r) -> Table IV, Column 3 (Panels A and B)
- [scripts/Extra_task_service_level_and_placebo.r](scripts/Extra_task_service_level_and_placebo.r) -> Extra task (service-level analysis + placebo pre-trend)

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
- [output/table_IV_col3_panelA.csv](output/table_IV_col3_panelA.csv) (Panel A table)
- [output/table_IV_col3_panelB.csv](output/table_IV_col3_panelB.csv) (Panel B table)
- [output/table_IV_col3_panelA.png](output/table_IV_col3_panelA.png) (Panel A visualization)
- [output/table_IV_col3_panelB.png](output/table_IV_col3_panelB.png) (Panel B visualization)

**Extra Task Outputs:**
- [output/extra_task_service_level_coefficients.csv](output/extra_task_service_level_coefficients.csv)
- [output/extra_task_service_level_key_periods.csv](output/extra_task_service_level_key_periods.csv)
- [output/extra_task_service_level_analysis.png](output/extra_task_service_level_analysis.png)
- [output/extra_task_service_placebo_pretrend.csv](output/extra_task_service_placebo_pretrend.csv)
- [output/extra_task_service_placebo_pretrend.png](output/extra_task_service_placebo_pretrend.png)

**Execution Logs:**
- [output/run_log.txt](output/run_log.txt) - Full `sink()` log with all console output
- [output/run_status.csv](output/run_status.csv) - Success/failure status by script

---

## 5) Replication notes

**Table 1 (Panels A & C):**  FULLY CORRECT
  - Summary statistics replicated accurately
  - All 27 variables (Panel A) and 17 variables (Panel C) match expected values

**Table II:** Regression coefficients computed (script runs without error)

**Table III, Panel A:**  UPDATED / FIXED SPECIFICATION
  - Original script now uses the Stata-aligned setup (`test = bonds_to_assess29_lev_std`)
  - Uses the original `post_detail` variable from the data
  - Uses panel lag `l(real_pc_rev_total_log, 1)` with `panel.id = ~ id_ + year`
  - Outputs were regenerated with the updated specification

**Table IV, Column 3:**  IMPLEMENTED
  - Panel A (FE-OLS): Maintenance & depreciation spending (logged)
  - Panel B (PPML): Capital outlay spending (level)
  - Treatment variable: debt/revenue ratio (1929, Moody-adjusted, standardized)
  - Generates separate PNG visualizations for each panel
  - Sample: Cities with valid Moody leverage data (check_moody filter +/-0.2)
  - Replication quality: coefficients are very close overall (typically within +/-0.01)
  - Remaining discrepancy: Panel B, 1941-43 interaction is about -0.18 in R vs about -0.09 in the reference table
  - Short interpretation: this likely reflects small implementation/data-construction differences between `fixest::fepois` and Stata `ppmlhdfe` in the late-period subsample, while the main pattern of results is preserved

**Extra task (service-level + placebo):** IMPLEMENTED
  - Service-level DiD estimates for 9 spending categories (log per-capita outcomes)
  - Same leverage treatment and Table III/IV-style controls
  - Added placebo pre-trend test on 1924-1928 (fake treatment in 1927-1928)
  - Model of interest: `i(post_detail, ref = 2) * debt_to_rev29_lev_moody_std`
  - Interpretation: coefficients are semi-elasticities in logs (approx. percent changes)
  - Key significant results from [output/extra_task_service_level_key_periods.csv](output/extra_task_service_level_key_periods.csv):
    - `Total`, 1929-1933: -0.023 (SE 0.009, p~0.010) -> about 2.3% lower spending per +1 SD leverage
    - `Total`, 1934-1938: -0.040 (SE 0.016, p~0.012) -> about 4.0% lower spending per +1 SD leverage
    - `Charity`, 1934-1938: -0.154 (SE 0.076, p~0.044) -> strongest category-specific significant cut
  - Most other service categories are not statistically significant in core periods; this supports a selective rather than uniform cutting pattern
  - Placebo result from [output/extra_task_service_placebo_pretrend.csv](output/extra_task_service_placebo_pretrend.csv):
    - Most placebo coefficients are near zero and insignificant, supporting no strong differential pre-trend
    - One borderline case remains (`School`, p~0.075), reported transparently as weak evidence at 10% level

All models use:
- City and year fixed effects as specified
- Standard errors clustered at city level
- Standardized variables for interpretation

---