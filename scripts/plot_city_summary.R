#!/usr/bin/env Rscript
## Script: plot_city_summary.R
## Purpose: Read `output/summary_stats_city.csv` and save a table graphic (PNG, PDF)

required_pkgs <- c("readr", "gridExtra", "grid", "reshape2")
missing_pkgs <- required_pkgs[!(required_pkgs %in% installed.packages()[, "Package"])]
if (length(missing_pkgs)) {
  stop(paste0("Please install required packages: ", paste(missing_pkgs, collapse = ", "),
              "\nRun: install.packages(c('", paste(missing_pkgs, collapse = "','"), "'))"))
}

library(readr)
library(gridExtra)
library(grid)
library(reshape2)

infile <- file.path("output", "summary_stats_city.csv")
if (!file.exists(infile)) stop("File not found: ", infile, " — run scripts/make_city_summary.R first")

tbl <- read_csv(infile, show_col_types = FALSE)

## Format numeric columns for nicer display
fmt_num <- function(x, digits = 2) {
  ifelse(is.na(x), "", format(round(x, digits), nsmall = digits, big.mark = ","))
}

tbl2 <- tbl
tbl2$N <- as.integer(tbl2$N)
tbl2$Mean <- fmt_num(tbl2$Mean, 2)
tbl2$SD <- fmt_num(tbl2$SD, 2)
tbl2$Median <- fmt_num(tbl2$Median, 2)
tbl2$`25 pct` <- fmt_num(tbl2$`25 pct`, 2)
tbl2$`75 pct` <- fmt_num(tbl2$`75 pct`, 2)

# Create a table grob
g <- tableGrob(tbl2, rows = NULL, theme = ttheme_minimal(base_size = 10))

dir.create("output", showWarnings = FALSE)
png(file.path("output", "summary_stats_city.png"), width = 1200, height = max(400, nrow(tbl2)*24), res = 150)
grid.newpage(); grid.draw(g)
dev.off()

pdf(file.path("output", "summary_stats_city.pdf"), width = 11, height = max(4, nrow(tbl2)*0.12))
grid.newpage(); grid.draw(g)
dev.off()

message("Wrote: output/summary_stats_city.png and output/summary_stats_city.pdf")
