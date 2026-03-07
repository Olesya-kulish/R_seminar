R REPLICATION INSTRUCTIONS (FINAL)
==================================

1) Open R or RStudio.

2) Set working directory to the project root:
   c:/Users/olesy/OneDrive/Dokumente/uni/R_Seminar/R_seminar

3) Install required packages once:
   install.packages(c("haven", "dplyr", "fixest", "tibble", "purrr", "flextable"))

4) Run the full automated replication:
   source("scripts/run_all_tables_with_log.r")

The runner script starts by loading the original replication data files:
- data/replication-data-city.dta
- data/replication-data-micro.dta

It then runs all table scripts and writes:
- output/run_log.txt      (full sink() execution log)
- output/run_status.csv   (success/failure by script)

Generated tables are saved automatically in output/ as CSV/PNG/TEX files.
