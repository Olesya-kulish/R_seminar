# Additional Analyses & Robustness Checks for "Public Goods Under Financial Distress"

## Executive Summary
This document proposes extensions to the paper's core analysis of how financial distress affected public spending during the Great Depression. These include robustness checks on the main findings, service-level analyses, mechanism exploration, and entirely new research directions.

---

# PART 1: ROBUSTNESS CHECKS ON MAIN ANALYSIS

## 1.1 Alternative Treatment Measures

**Current approach:** Debt-to-revenue ratio in 1929

**Alternative measures to test:**
- **Debt-to-assessed value** instead of revenue (some cities may have had volatile revenues)
- **Interest-to-revenue ratio** (measures ongoing debt service burden, not just stock)
- **Bond maturity structure** (cities with many short-term bonds faced more refinancing risk in 1930s)
- **Debt per capita** (controls for city size differently)
- **Leverage relative to peer cities** (within-state or within-region percentile ranking)

**Why this matters:** Different leverage measures capture different aspects of financial fragility. If results hold across multiple measures, the finding is more robust.

---

## 1.2 Time Period Sensitivity

**Current approach:** 5 periods (1924-26, 1927-28, 1929-33, 1934-38, 1941-43)

**Alternative periodizations:**
- **Finer granularity:** Year-by-year coefficients instead of period bins (shows when exactly spending fell)
- **Different crisis windows:** Define "crisis" as 1930-1933 only vs 1929-1938 vs 1929-1943
- **Exclude Reconstruction Finance Corporation (RFC) effects:** Test 1941-43 separately (was spending stimulated by federal programs?)
- **Detrending analysis:** Subtract pre-1929 trend to see if cities reverted to trend or fell below

**Why this matters:** Robustness to different assumptions about when the crisis "started" and "ended."

---

## 1.3 Placebo Tests (Falsification Tests)

**Current threat:** Unmeasured confounding. Maybe high-leverage cities were already cutting spending before the crash.

**Tests to run:**
- **Pre-crisis placebo:** Use pre-1929 periods as "treatment" (e.g., 1927-28 vs 1924-26)
  - If coefficient ≈ 0 in pre-period, this supports causality
- **Alternative "crisis" years:** Randomly assign cities to fake crisis years
  - If fake crisis shows effect, the finding is spurious
- **Non-financial shocks:** Test whether leverage predicts response to non-financial events
  - E.g., does leverage predict mortality response to flu outbreaks? (should be NO)

**Why this matters:** Separates causal effect from selection bias.

---

## 1.4 Alternative Sample Restrictions

**Current approach:** Moody's-rated cities with quality check (-0.2 < check_moody < 0.2)

**Alternative samples:**
- **Without quality filter:** Include all Moody's-rated cities (are outliers driving results?)
- **Unbalanced panel:** Don't require cities in all years (do results hold?)
- **By city size:** Separate effects for large vs small cities (is mechanism different?)
- **By region:** North vs South vs West (did policy responses differ?)
- **Exclude state capitals:** Are state capitols different due to state support?

**Why this matters:** Tests whether findings are driven by outliers or specific city types.

---

## 1.5 Heterogeneous Treatment Effects

**Hypothesis:** Effect of leverage may differ by city characteristics

**Analyses:**
- **By initial fiscal health:** Did cities with existing deficits cut spending more?
- **By population growth:** Did growing cities cut spending differently than shrinking cities?
- **By industrial composition:** Did manufacturing cities respond differently than commercial centers?
- **By debt type:** Did cities with many bonds behave differently than those with bank loans?
- **By pre-Depression wealth:** Did wealthy cities cut less (had reserves) than poor cities?

**Method:** Estimate separate models by subgroup, or use interactions: `leverage × leverage_group`

**Why this matters:** Identifies which cities were most vulnerable (policy implications).

---

# PART 2: SERVICE-LEVEL ANALYSIS

## 2.1 Spending Cuts by Service Type

**Current approach:** Aggregate maintenance and capital spending

**Service-specific analyses:**
```
Available data in dataset:
- real_pc_maint_dep_total_log (aggregate)
- real_pc_maint_dep_gen (general maintenance)
- real_pc_maint_dep_health
- real_pc_maint_dep_road
- real_pc_maint_dep_pp (public property)
- real_pc_maint_dep_charity
- real_pc_maint_dep_rec (recreation)
- real_pc_maint_dep_school
```

**Research questions:**
- **Political priorities:** Did cities protect school/health spending vs "luxury" services?
- **Essential vs discretionary:** Was road maintenance cut more than police? (roads = infrastructure)
- **Externalities:** Did cuts to health services show up in mortality/disease data?

**Mechanism hypothesis:** Cities may have cut discretionary services (parks, recreation) while maintaining essential services (roads, police), revealing political priorities during crisis.

---

## 2.2 Long-Term Consequences of Spending Cuts

**Current approach:** Analyzes spending during Depression only

**New analysis:** Link Depression-era spending cuts to later outcomes

**Data to merge:**
- **1940 Census:** Population, education, age structure
- **Post-war outcomes:** Compare trajectory 1945-1950 for high-leverage vs low-leverage cities
  - Did deferred maintenance translate to lower population?
  - Did spending cuts in schools show up in education levels?
- **Modern data (2000s):** Compare city quality-of-life today
  - Do cities that cut spending during Depression still have worse infrastructure?

**Hypothesis:** Financial distress in 1929-38 created persistent disadvantage for high-leverage cities.

---

# PART 3: MECHANISM EXPLORATION

## 3.1 Crowding Out Analysis

**Current question:** Did debt service consume the budget, leaving less for services?

**Analysis:**
- Calculate: `spending_cuts = leverage × crisis_period`
- Compare to: `debt_service_changes` in same periods
- Regression: `real_pc_maint ~ debt_service_burden + leverage + controls`
  - Does adding debt service burden make leverage coefficient smaller? (evidence of crowding out)

**Data needed:** Interest payment data (may be in dataset as `real_pc_interest`)

**Hypothesis:** High-leverage cities had to allocate larger share of budgets to debt service → less for services.

---

## 3.2 Revenue Constraint vs Expenditure Choice

**Current question:** Did high-leverage cities cut spending because revenues fell, or choice?

**Analysis:**
- Decompose spending change: Spending_t - Spending_t-1 = (Revenue_t - Revenue_t-1) + (Discretionary_Choice)
- Estimate: `spending_change ~ revenue_change + leverage + controls`
  - Large coefficient on revenue → spending cuts driven by revenue loss
  - Significant residual → cities made active choices to cut beyond what revenue loss necessitated

**Data needed:** Revenue components (`real_pc_rev_tax`, `real_pc_rev_debt`, `real_pc_rev_nontax`)

**Hypothesis:** High-leverage cities cut MORE than revenue losses alone would predict → fiscal consolidation policy.

---

## 3.3 Default Risk & Debt Restructuring

**Current approach:** Analyzes spending, not financial outcomes

**New analysis:** Did high-leverage cities default?

**Data to create:**
- `default` variable (likely in dataset already)
- Compare: Did high-leverage cities have higher default rates?
  - Logit/Probit: `P(default) = f(leverage, year_dummies, controls)`

**Research question:** Was spending restraint a strategy to AVOID default, or did default force spending cuts?

**Timeline analysis:**
- If cities cut spending BEFORE default → suggest fiscal consolidation strategy
- If default THEN spending cuts → suggest forced adjustment by creditors

---

## 3.4 Federal Program Effects (RFC & WPA)

**Current data:** Likely includes `WPA_pc` and `RFC_pc` (federal relief spending)

**Analysis:**
- Did federal relief substitute for, or complement, local spending?
- Estimate: `local_spending ~ federal_spending + leverage + controls`
  - Coefficient near -1 → complete crowding out
  - Coefficient near 0 → no substitution
- Did federal programs offset leverage effects?
  - Estimate: `spending ~ leverage + leverage × federal_dummy + controls`
  - Does federal program participation eliminate the leverage effect?

**Hypothesis:** Federal relief may have relaxed the constraint for high-leverage cities.

---

# PART 4: ENTIRELY NEW ANALYSES

## 4.1 Wage Effects: Did Public Sector Employment Fall?

**New outcome variables** (if available in micro data):
- Number of public employees by function
- Wages of public employees
- Job loss rates in public sector

**Research question:** Did spending cuts translate to layoffs, or wage cuts, or reduced hours?

**Significance:** Human impact of austerity during Depression.

---

## 4.2 Spillovers: Did Austerity Affect Private Sector?

**Hypothesis:** City spending cuts → fewer contracts for private firms → private sector depression

**Analysis:** Link city spending to county-level economic indicators
- Merge with: County unemployment, manufacturing employment, retail sales
- Estimate: `county_employment ~ municipal_spending + controls`

**Alternative:** Use regional spillovers
- If City A cuts spending, does nearby City B lose economic activity?
- Geographic diff-in-diff approach

---

## 4.3 Political Economy: Why Did Some Cities Cut More Than Others?

**Current approach:** Assumes cities respond uniformly to leverage

**Alternative hypothesis:** Political factors determine response

**New variables to collect:**
- Mayor's party affiliation
- State government ideology (Democratic vs Republican)
- History of corruption/scandals
- Union strength in city

**Analysis:**
- Estimate: `spending_cut ~ leverage × political_affiliation + controls`
- Does partisan ideology predict spending cuts?
- Did cities with strong unions protect public sector wages?

---

## 4.4 Comparative Analysis: Other Countries' Great Depressions

**Hypothesis:** Pattern of leverage → austerity should be universal

**Analysis:** Extend to:
- **Canadian cities:** Similar time period, similar federal structure
- **German cities:** Weimar hyperinflation + Great Depression (extreme case)
- **British cities:** Different monetary framework (gold standard earlier exit)

**Method:** Replicate analysis on city-level data from other countries

**Significance:** Shows whether mechanism is economic fundamentals or US-specific.

---

## 4.5 Historical Comparison: 1920-21 Recession vs 1929 Depression

**Hypothesis:** Same mechanism should apply to other financial crises

**Analysis (MASTER'S THESIS FEASIBLE):** Compare spending response in two Depression-era shocks
- **Crisis 1:** 1920-21 recession (sharp but short-lived; no federal intervention)
- **Crisis 2:** 1929-38 Great Depression (prolonged; federal intervention via RFC/WPA)
- Same DiD design as main analysis, but compare across TWO crises in same dataset

---

### THE CORE IDEA: Natural Experiment on Federal Policy

**Two economic crises, two different policy responses:**

**1920-21 Recession:**
- Post-WWI deflation shock (sharp economic contraction)
- Federal government did NOTHING (laissez-faire policy under Harding)
- Cities were on their own to manage fiscal crisis
- Crisis lasted ~18 months, then recovery

**1929-38 Great Depression:**
- Stock market crash, bank failures, prolonged contraction
- Federal government intervened (RFC in 1932, WPA in 1935, other New Deal programs)
- Cities received federal loans, grants, relief programs
- Crisis lasted nearly a decade

**Natural experiment:** Do cities with high leverage cut spending LESS when federal government helps?

---

### RESEARCH QUESTION

**Main question:** Did federal intervention (RFC/WPA) mitigate the effect of financial leverage on spending cuts?

**Specific hypotheses:**
1. **H1:** In 1920-21 (no federal help), high-leverage cities cut spending MORE than low-leverage cities
2. **H2:** In 1929-38 (with federal help), high-leverage cities ALSO cut spending more, BUT the effect is smaller
3. **H3:** The difference between H1 and H2 tells us: How much did federal intervention matter?

**Example prediction:**
- 1920-21: High-leverage cities cut spending 15% more than low-leverage cities
- 1929-38: High-leverage cities cut spending only 5% more than low-leverage cities
- **Conclusion:** Federal intervention reduced the leverage penalty by 10 percentage points

---

### WHY THIS IS INTERESTING

**Policy relevance:**
- Modern debate: Should federal government bail out financially distressed cities?
- Your analysis shows: Did it work historically?
- If federal programs eliminated the leverage effect → strong case for intervention
- If federal programs did nothing → weak case for intervention

**Economic insight:**
- Tests whether fiscal federalism matters
- Shows how external financing (federal loans) affects local decisions
- Reveals whether cities used federal money to maintain services or pay down debt

**Historical context:**
- 1920-21 recession is understudied (overshadowed by Great Depression)
- Comparing the two crises gives new perspective on both

---

### WHAT YOU WOULD ACTUALLY DO

#### Step 1: Define Crisis Periods

**For 1920-21 Recession:**
```r
# Create crisis period indicators
df <- df %>%
  mutate(
    crisis_1920 = case_when(
      year %in% 1919:1920 ~ "before",       # Pre-recession baseline
      year %in% 1921:1922 ~ "during",       # Recession peak
      year %in% 1923:1924 ~ "after",        # Recovery
      TRUE ~ NA_character_
    )
  )
```

**For 1929-38 Depression:**
```r
# Already have post_detail from main analysis
# Period 2 (1927-28) = before
# Period 3 (1929-33) = crisis
# Period 4 (1934-38) = recovery with federal programs
```

---

#### Step 2: Estimate Separate DiD Models

**Model for 1920-21 Crisis:**
```r
model_1920 <- feols(
  real_pc_maint_dep_total_log ~ 
    i(crisis_1920, leverage, ref = "before") +  # Compare during/after to before
    i(year, ref = 1919) +                       # Year fixed effects
    real_pc_rev_total_log |                     # Control for revenue
    id_,                                        # City fixed effects
  data = df[df$year %in% 1918:1925, ],          # Restrict to 1920s crisis window
  vcov = ~ id_
)

# Extract coefficient: Did high-leverage cities cut spending during 1921-22?
coef_1920_during <- coef(model_1920)["crisis_1920::during:leverage"]
```

**Model for 1929-38 Depression (already estimated!):**
```r
# Use your existing Panel A model
model_1930 <- mA  # Your existing model from main analysis

# Extract coefficient: Did high-leverage cities cut spending in 1929-33?
coef_1930_during <- coef(model_1930)["post_detail::3:debt_to_rev29_lev_moody_std"]
```

---

#### Step 3: Compare Across Crises

**Statistical test:**
```r
# Bootstrap or Wald test to compare coefficients
# Question: Is coef_1920_during DIFFERENT from coef_1930_during?

library(car)  # For linearHypothesis test
# Combine models into stacked regression with crisis×leverage interaction
model_stacked <- feols(
  real_pc_maint_dep_total_log ~ 
    i(crisis_period, leverage) * crisis_type +  # crisis_type = "1920s" or "1930s"
    controls | id_ + year,
  data = df_combined
)

# Test: leverage_effect_1920s = leverage_effect_1930s?
linearHypothesis(model_stacked, "leverage_1920s - leverage_1930s = 0")
```

**Visual comparison:**
```r
# Create coefficient plot comparing the two crises
library(ggplot2)
coef_comparison <- data.frame(
  Crisis = c("1920-21 Recession", "1929-33 Depression"),
  Coefficient = c(coef_1920_during, coef_1930_during),
  SE = c(se_1920, se_1930)
)

ggplot(coef_comparison, aes(x = Crisis, y = Coefficient)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = Coefficient - 1.96*SE, ymax = Coefficient + 1.96*SE), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(title = "Effect of Leverage on Spending Cuts: 1920s vs 1930s",
       y = "Spending Cut (% per SD leverage)")
```

---

#### Step 4: Mechanism Analysis — Where Did Federal Money Go?

**Question:** If leverage effect was smaller in 1930s, was it because federal programs helped?

**Test:**
```r
# Merge in federal program data (RFC loans, WPA spending)
df <- df %>%
  left_join(federal_programs, by = c("id_", "year"))

# Estimate: Did federal aid offset leverage effects?
model_mechanism <- feols(
  real_pc_maint_dep_total_log ~
    i(post_detail, leverage, ref = 2) +           # Main leverage effect
    RFC_pc + WPA_pc +                             # Federal aid variables
    i(post_detail, leverage, ref = 2) * (RFC_pc + WPA_pc) |  # Interaction
    id_ + year,
  data = df,
  vcov = ~ id_
)

# Interpretation:
# - Main leverage coefficient = effect WITHOUT federal aid
# - Interaction coefficient = does federal aid reduce leverage penalty?
# - If interaction is POSITIVE → federal aid offset spending cuts
```

---

### WHAT YOUR THESIS WOULD SHOW

**Possible Finding 1: Federal Programs Worked**
- 1920-21: High-leverage cities cut spending 12% more
- 1929-33: High-leverage cities cut spending only 2% more
- **Conclusion:** RFC/WPA allowed distressed cities to maintain services despite leverage

**Possible Finding 2: Federal Programs Didn't Help**
- 1920-21: High-leverage cities cut spending 12% more
- 1929-33: High-leverage cities cut spending 15% more
- **Conclusion:** Federal aid went to debt service, not service provision (creditor bailout, not city bailout)

**Possible Finding 3: Federal Programs Prolonged Crisis**
- 1920-21: High-leverage cities cut spending during crisis, but recovered quickly
- 1929-33: High-leverage cities maintained spending longer, but recovery took longer
- **Conclusion:** Federal aid enabled cities to avoid hard choices, delaying adjustment

---

### DATA YOU ALREADY HAVE

Your dataset includes:
- `WPA_pc` — WPA spending per capita by city-year
- `RFC_pc` — Reconstruction Finance Corporation loans per capita
- All the leverage measures
- All the spending measures
- Full panel 1924-1943 (covers both crises!)

**You literally just need to:**
1. Create 1920-21 period indicators
2. Run the same DiD model on different time windows
3. Compare coefficients
4. Done!

---

### TIMELINE FOR MASTER'S THESIS

**Week 1-2:** Literature review
- Read papers on 1920-21 recession
- Read papers on fiscal federalism
- Frame your contribution

**Week 3-4:** Data preparation
- Create 1920-21 crisis indicators
- Verify federal program variables
- Descriptive statistics

**Week 5-6:** Main analysis
- Estimate 1920-21 model
- Compare to 1929-38 model
- Statistical tests for difference

**Week 7-8:** Mechanism analysis
- Test RFC/WPA interaction effects
- Explore heterogeneity (by city size, region)

**Week 9-10:** Robustness checks
- Alternative crisis windows
- Different leverage measures
- Sample restrictions

**Week 11-12:** Writing and figures
- Introduction and motivation
- Results tables and coefficient plots
- Discussion and conclusion

**Total:** 12 weeks = 3 months = realistic master's timeline

---

### WHY PROFESSORS WILL LIKE THIS

✅ **Original contribution:** No one has systematically compared these two crises this way
✅ **Clear counterfactual:** 1920-21 is the "no federal intervention" baseline
✅ **Policy relevant:** Answers question about effectiveness of federal fiscal support
✅ **Methodologically sound:** Same DiD approach, same data, parallel research design
✅ **Feasible:** All data exists, no collection needed, clear scope
✅ **Publishable:** Could become a journal article with good execution

---

### POTENTIAL EXTENSIONS (IF YOU HAVE TIME)

1. **Heterogeneity:** Did federal programs help small cities more than large cities?
2. **Timing:** When exactly did federal aid arrive? Did spending adjust immediately?
3. **Composition:** Did federal money substitute for local revenue, or supplement it?
4. **Long-term:** Did cities that received more federal aid have worse fiscal health in 1940s?

---

### BOTTOM LINE

This turns your replication exercise into **original research** by asking:
- **Your replication:** Did leverage cause austerity in Great Depression? ✓
- **Your thesis:** Did federal intervention mitigate that effect? ← NEW QUESTION

It's a natural extension, uses data you have, and addresses a question people still care about today (federal bailouts of state/local governments during COVID-19, 2008, etc.).

---

## 4.6 Intergenerational Effects: Was Depression-Era Austerity Optimal?

**Hypothesis:** Cities cutting spending in 1930s may have caused persistent harm

**Analysis:**
- Compare cities with high vs low Depression-era cuts
- Track outcomes through 20th century:
  - 1950 Census: educational attainment, occupational distribution
  - 1980 Census: income, poverty rates
  - 2000 Census: metropolitan area growth rates

**Research question:** Did spending cuts create trapped poverty, or did resilience from austerity help later?

---

## 4.7 Infrastructure Quality Today: Legacy of Deferred Maintenance

**Hypothesis:** Cities that cut maintenance in 1930s-1940s have worse infrastructure today

**Analysis:**
- Merge with modern infrastructure data:
  - Road quality ratings (USDOT pavement condition surveys)
  - Bridge condition data
  - Utility system age and condition
- Regression: `infrastructure_quality_2020 ~ maintenance_cuts_1930s + controls`

**Significance:** Shows long-term cost of austerity.

---

# PART 5: METHODOLOGICAL EXTENSIONS

## 5.1 Synthetic Control Method

**Current approach:** Difference-in-Differences (parallel trends assumption)

**Alternative approach:** Synthetic Control
- Create synthetic "low-leverage city" as weighted average of similar cities
- Compare actual high-leverage city to its synthetic control
- More flexible than parallel trends assumption

**Benefit:** Can visualize treatment effect over time, relaxes assumptions.

---

## 5.2 Local Polynomial Regression Discontinuity (RDD)

**Current approach:** Compare discrete leverage groups

**Alternative approach:** RDD around cutoffs
- If cities above certain leverage threshold were treated differently (e.g., not allowed to borrow)
- Use the threshold as RDD cutoff
- Estimates local effect for cities near threshold

**Benefit:** Stronger causality claim for cities right at boundary.

---

## 5.3 Event Study Design

**Current approach:** Period dummies

**Alternative approach:** Event study
- Define event: Year of maximum stock market decline or bank failure in each city
- Estimate dynamic effects: `spending_t+k = f(leverage, event_time_k)`
- Shows response path over time (6 months after event, 12 months, 24 months, etc.)

**Benefit:** More detailed picture of adjustment process.

---

## 5.4 Machine Learning Prediction

**Question:** Can we predict which cities would cut spending most severely?

**Approach:** Train model on pre-1929 city characteristics
- Use pre-1929 data: population, wealth, economic structure, education, fiscal health
- Predict: magnitude of spending cuts in 1930-1938
- Compare predictions to actual outcomes

**Benefit:** Identifies which characteristics made cities vulnerable.

---

# PART 6: DATA COMBINATION & LINKAGES

## 6.1 Mortality & Health Outcomes

**Hypothesis:** Spending cuts on health/sanitation increased mortality

**Data to merge:**
- City-level mortality by cause (pneumonia, tuberculosis, diarrheal diseases)
- Public health spending by city
- Regression: `mortality_rate ~ public_health_spending + leverage + year_FE`

**Significance:** Shows human cost of austerity.

---

## 6.2 Crime Data

**Hypothesis:** Job loss from spending cuts increased crime

**Data to merge:**
- City crime statistics (1920s-1940s recorded in some archives)
- Public sector employment by city
- Regression: `crime_rate ~ public_employment + controls`

---

## 6.3 Education Outcomes

**Hypothesis:** Spending cuts on schools reduced educational attainment

**Data to merge:**
- School enrollment and per-pupil spending by city (if available)
- 1940 Census school attendance rates
- 1950 Census educational attainment
- Regression: `educational_attainment_1950 ~ school_spending_cuts_1930s`

---

# RECOMMENDED PRIORITY

If you had to choose which analyses to suggest to the authors:

**High Priority (most directly relevant):**
1. Service-level analysis (2.1) — Understanding what was cut
2. Placebo tests (1.3) — Strongest robustness check
3. Heterogeneous effects (1.5) — Policy relevance
4. Mechanism: crowding out (3.1) — Understand HOW leverage matters

**Medium Priority (extends findings):**
5. Long-term consequences (2.2) — shows persistence
6. 2008 replication (4.5) — shows generalizability

**Low Priority (interesting but speculative):**
7. Modern infrastructure (4.7) — harder to attribute causally
8. Comparative international (4.4) — different institutional contexts

---

# CONCLUSION

The paper's core finding—that financial leverage caused austerity during the Great Depression—is solid. These additional analyses would:
- **Strengthen it** (robustness checks, mechanisms)
- **Extend it** (service-level, temporal, heterogeneous effects)
- **Contextualize it** (compare to modern crises, show long-term effects)
- **Deepen it** (explore human consequences, political factors)

The most impactful would likely be: (1) replicating on 2008 crisis data to show the mechanism is universal, and (2) linking to long-term outcomes to show austerity had persistent costs.
