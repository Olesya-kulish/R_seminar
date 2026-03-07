# Presentation Snippets: Table IV Replication

## Snippet 1: The Difference-in-Differences Design (THE CORE)

```r
"real_pc_maint_dep_total_log ~ 
  i(post_detail, ref = 2) * testvar +      # Compare high vs low leverage across time periods
  i(year, ref = 1928) +                    # Account for economy-wide changes each year
  i(year, pop_30, ref = 1928) +            # Account for population growth differences
  i(year, pop_20_30, ref = 1928) + 
  real_pc_rev_total_log +                  # Control: current budget size
  l(real_pc_rev_total_log, 1) +            # Control: previous year's budget (inertia)
  i(year, region_) | id_"                  # Account for regional shocks + city characteristics
```

### What This Does (In Plain English)

**The main question:** "Did cities with high debt in 1929 cut spending MORE during the Great Depression?"

**How we answer it:**
- Compare **high-leverage cities** vs **low-leverage cities** (the leverage groups)
- Across **5 time periods:** pre-crisis (1927-28), early crisis (1929-33), recovery (1934-38), war (1941-43)
- The reference period 1927-28 = "normal times"
- So the coefficient tells us: "In period X, how much MORE did high-leverage cities cut spending compared to their pre-crisis level?"

**Why we add controls:**
- `i(year, ref = 1928)` — Not all changes in spending are due to leverage. The whole economy changed. So we control for year-to-year changes that affect ALL cities.
- `real_pc_rev_total_log` — Rich cities spend more than poor cities. We control for that.
- `l(real_pc_rev_total_log, 1)` — Cities tend to keep spending at similar levels year-to-year (budget inertia). We control for that too.
- `| id_` — Each city has its own baseline characteristics (location, size, governance style). We account for those.

**The result:** A "clean" comparison of high vs low-leverage cities, isolated from other confounding factors.

---

## Snippet 2: Why We Use Different Statistical Models for Different Outcomes

```r
# Panel A: OLS for continuous outcome (maintenance spending in dollars)
mA <- fixest::feols(fml = make_fml_A(testvar), data = df0, vcov = ~ id_)

# Panel B: Poisson (PPML) for count outcome (number of capital projects: 0, 1, 2, 3...)
mB <- fixest::fepois(fml = make_fml_B(testvar), data = df0, vcov = ~ id_)
```

### What This Does (In Plain English)

**Two different outcomes, two different statistical tools:**

**Panel A:** Maintenance spending is measured in **dollars** (a continuous number)
- Example: City A spends $50,000, City B spends $75,000
- We use **OLS** (standard regression) — works great for continuous dollar amounts
- Coefficient interpretation: "High-leverage cities cut maintenance by X% compared to low-leverage cities"

**Panel B:** Capital projects are **counts** (how many projects: 0, 1, 2, 3...)
- Example: City A does 3 capital projects, City B does 0 projects
- Problem with OLS: It might predict negative counts (impossible!)
- Solution: Use **Poisson** (a special regression for count data) — handles the constraint that counts can't be negative
- Coefficient interpretation: "High-leverage cities reduced capital projects by X% compared to low-leverage cities"

**Why this matters:**
You wouldn't measure "number of apples" the same way you measure "weight in pounds" — different tools for different types of measurements. Same principle here.

---

## How to Present This

### Opening (30 seconds):
*"Our analysis uses a Difference-in-Differences design. The key idea is simple: we compare cities that were financially fragile in 1929 — those with high debt — to cities that were financially healthy. Then we see if the fragile ones cut spending MORE during the Depression. The code shows how we build this comparison while controlling for other factors that might affect spending."*

### On Snippet 1 (45 seconds):
*"The formula here is the econometric model. The asterisk between `post_detail` and `testvar` means we're comparing periods AND comparing high vs low leverage. The other terms — the population controls, revenue controls, region effects — those are just making sure we're comparing apples to apples. Every time period, every region, every city size gets accounted for so the comparison is fair."*

### On Snippet 2 (30 seconds):
*"Because maintenance spending and capital projects are different types of measurements — one is continuous dollars, one is a discrete count — we use two different statistical approaches. OLS for the spending amounts, Poisson for the project counts. It's not that one is better; they're just appropriate for different data types."*

---

## One More Thing: Show You Read the Code

Add this throwaway line somewhere:
*"We filtered the data to only include cities where the Moody's quality check fell between -0.2 and 0.2, which gave us about 3,800 observations to work with. This ensures we're using reliable financial data."*

This shows:
- You understand what `check_moody < 0.2 & check_moody > -0.2` does
- You know your sample size
- You understand why data cleaning matters

---

## Your Script (What NOT to Put On Slides)

Don't put on your presentation:
- The helper functions (pstars, y_stats_fixest, extract_4_inter) — too technical
- The PNG generation code — not relevant to the analysis
- The lag operator issue — if professor doesn't ask about it, don't volunteer it
- Matrix algebra or statistical theory — keep it practical

Do explain clearly:
- What the treatment is (high leverage in 1929)
- What the outcomes are (maintenance spending, capital projects)
- Why you use different models (continuous vs count data)
- What the comparison shows (financial distress → spending cuts)
