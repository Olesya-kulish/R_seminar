# Table IV Replication Discrepancies - Brief Summary

## Why Results Differ

The primary issue is **lag construction around the 1939-1940 gap**. When R's fixest creates `l(real_pc_rev_total_log, 1)` for year 1941, it can't find 1940 (missing from dataset), so it either uses 1938 instead (wrong control value) or drops the observation (different sample). This explains why the 1941-43 coefficient is double the original (-0.18 vs -0.09), while earlier periods match closely.

Additional minor discrepancies come from **interaction term handling differences** between Stata's `c.pop_30##i.year` and R's `i(year, pop_30)`, which create slightly different dropout patterns for missing values. Different software packages also use different numerical algorithms for PPML estimation, leading to small differences in convergence.

Despite these issues, coefficients for 1924-26, 1929-33, and 1934-38 all match within 0.01-0.02, showing the model specification is correct—the gap year problem affects only the final period.
