# Recreate City-Level Summary Table

This repository includes a script to recreate the city-level summary table (Panel A) shown in the attachment.

How to run (R required):

1. Install required R packages (if not already installed):

```r
install.packages(c('haven','dplyr','tibble','xtable','purrr'))
```

2. Run the script from the project root:

```sh
Rscript scripts/make_city_summary.R
```

Outputs:
- `output/summary_stats_city.csv` — CSV of the summary table
- `output/summary_stats_city.tex` — basic LaTeX table (user can further format)

Table graphic (PNG/PDF):

1. After running `scripts/make_city_summary.R`, run the plotting script:

```sh
Rscript scripts/plot_city_summary.R
```

2. This writes `output/summary_stats_city.png` and `output/summary_stats_city.pdf`.
