# Table IV Column (3)
# Panel A: FE-OLS on real_pc_maint_dep_total_log
# Panel B: PPML on real_pc_outlay

# ============================================
# Packages
# ============================================

pkgs <- c("haven", "dplyr", "fixest", "stringr")
need <- pkgs[!sapply(pkgs, requireNamespace, quietly = TRUE)]
if (length(need) > 0) install.packages(need, repos = "https://cloud.r-project.org")
invisible(lapply(pkgs, library, character.only = TRUE))

# ============================================
# 1) Read data
# ============================================

df <- haven::read_dta("data/replication-data-city.dta")
stopifnot("check_moody" %in% names(df))

# ============================================
# 2) Preprocess
# ============================================

df0 <- df %>%
  dplyr::filter(check_moody < 0.2, check_moody > -0.2) %>%
  dplyr::mutate(
    id_ = as.factor(id_),
    year = as.integer(year),
    region = as.factor(region_),
    post_detail = as.integer(post_detail)
  )

# ============================================
# 3) Helpers
# ============================================

pstars <- function(p) {
  s <- rep("", length(p))
  ok <- !is.na(p)
  s[ok & p < 0.10] <- "*"
  s[ok & p < 0.05] <- "**"
  s[ok & p < 0.01] <- "***"
  s
}

y_stats_fixest <- function(m) {
  y <- as.numeric(m$fitted.values) + as.numeric(m$residuals)
  c(mean = mean(y, na.rm = TRUE), sd = sd(y, na.rm = TRUE))
}

safe_wr2 <- function(m) {
  out <- tryCatch(fixest::fitstat(m, "wr2"), error = function(e) NA_real_)
  as.numeric(out)
}

safe_pr2 <- function(m) {
  out <- tryCatch(fixest::fitstat(m, "pr2"), error = function(e) NA_real_)
  as.numeric(out)
}

extract_4_inter <- function(m, testvar) {
  ct <- fixest::coeftable(m)
  rn <- rownames(ct)
  pat <- paste0("^", testvar, ":post_detail::(1|3|4|5)$")
  idx <- stringr::str_detect(rn, pat)
  ct2 <- ct[idx, , drop = FALSE]
  stopifnot(nrow(ct2) == 4)
  g <- as.integer(stringr::str_match(rownames(ct2), "post_detail::(\\d+)")[, 2])
  ord <- order(g)
  ct2 <- ct2[ord, , drop = FALSE]
  cand <- c("Pr(>|t|)", "Pr(>|z|)", "Pr(>|chi|)")
  p_col <- intersect(cand, colnames(ct2))[1]
  stopifnot(!is.na(p_col))
  est <- ct2[, "Estimate"]
  se <- ct2[, "Std. Error"]
  p <- ct2[, p_col]
  st <- pstars(p)
  list(
    est = sprintf("%.2f%s", est, st),
    se = sprintf("(%.2f)", se)
  )
}

term_show <- c(
  "moodyleverage x 1924-1926",
  "moodyleverage x 1929-1933",
  "moodyleverage x 1934-1938",
  "moodyleverage x 1941-1943"
)

# ============================================
# Column 3 only: debt_to_rev29_lev_moody_std
# ============================================

a_name <- "debt_to_rev29_lev"
testvar <- paste0(a_name, "_moody_std")
stopifnot(testvar %in% names(df0))

# ============================================
# Panel A: FE-OLS (Table IV A) — outcome real_pc_maint_dep_total_log
# ============================================

make_fml_A <- function(tv) {
  as.formula(paste0(
    "real_pc_maint_dep_total_log ~ ",
    "i(post_detail, ref = 2) * ", tv, " + ",
    "i(year, ref = 1928) + ",
    "i(year, pop_30, ref = 1928) + ",
    "i(year, pop_20_30, ref = 1928) + ",
    "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) + ",
    "i(year, region_) | id_"
  ))
}

mA <- fixest::feols(
  fml = make_fml_A(testvar),
  data = df0,
  vcov = ~ id_,
  panel.id = ~ id_ + year
)

dA <- extract_4_inter(mA, testvar)
ysA <- y_stats_fixest(mA)

# Build coefficient table for Panel A
rowA <- data.frame(term = rep(term_show, each = 2), stringsAsFactors = FALSE)
rowA$m3 <- as.vector(rbind(dA$est, dA$se))
rowA$term[seq(2, nrow(rowA), by = 2)] <- ""

gofA <- data.frame(
  term = c("City FE", "Year FE", "1930 Pop x Year", "1920-30 Pop x Year", "Revenue", "Region x Year", "R-sq (within)", "N", "Mean(y)", "SD(y)"),
  m3 = c(
    "Y", "Y", "Y", "Y", "Y", "Y",
    sprintf("%.2f", safe_wr2(mA)),
    as.character(stats::nobs(mA)),
    sprintf("%.2f", ysA["mean"]),
    sprintf("%.2f", ysA["sd"])
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

tabA <- dplyr::bind_rows(rowA, gofA)
colnames(tabA) <- c("", "Debt/Rev (FE-OLS)")

# ============================================
# Panel B: PPML (Table IV B) — outcome real_pc_outlay
# ============================================

make_fml_B <- function(tv) {
  as.formula(paste0(
    "real_pc_outlay ~ ",
    "i(post_detail, ref = 2) * ", tv, " + ",
    "i(year, pop_30, ref = 1928) + ",
    "i(year, pop_20_30, ref = 1928) + ",
    "real_pc_rev_total_log + l(real_pc_rev_total_log, 1) + ",
    "i(year, region_) | id_ + year"
  ))
}

mB <- fixest::fepois(
  fml = make_fml_B(testvar),
  data = df0,
  vcov = ~ id_,
  panel.id = ~ id_ + year
)

dB <- extract_4_inter(mB, testvar)
ysB <- y_stats_fixest(mB)

rowB <- data.frame(term = rep(term_show, each = 2), stringsAsFactors = FALSE)
rowB$m3 <- as.vector(rbind(dB$est, dB$se))
rowB$term[seq(2, nrow(rowB), by = 2)] <- ""

gofB <- data.frame(
  term = c("City FE", "Year FE", "1930 Pop x Year", "1920-30 Pop x Year", "Revenue", "Region x Year", "R-sq (pseudo)", "N", "Mean(y)", "SD(y)"),
  m3 = c(
    "Y", "Y", "Y", "Y", "Y", "Y",
    sprintf("%.2f", safe_pr2(mB)),
    as.character(stats::nobs(mB)),
    sprintf("%.2f", ysB["mean"]),
    sprintf("%.2f", ysB["sd"])
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

tabB <- dplyr::bind_rows(rowB, gofB)
colnames(tabB) <- c("", "Debt/Rev (PPML)")

# ============================================
# Write outputs
# ============================================

dir.create("output", showWarnings = FALSE)

# Console heads-up
cat("\nPanel A (FE-OLS) N:", stats::nobs(mA), "| R-sq(within):", sprintf("%.3f", safe_wr2(mA)), "\n")
cat("Panel B (PPML)  N:", stats::nobs(mB), "| R-sq(pseudo):", sprintf("%.3f", safe_pr2(mB)), "\n")

# --------------------------------------------
# CSV outputs (coef + se + stats)
# --------------------------------------------

csv_coef <- data.frame(
  panel = rep(c("A", "B"), each = 4),
  estimator = rep(c("FE-OLS", "PPML"), each = 4),
  period = rep(c("1924-1926", "1929-1933", "1934-1938", "1941-1943"), times = 2),
  coef = c(mA$coeftable[paste0(testvar, ":post_detail::", c(1,3,4,5)), "Estimate"],
           mB$coeftable[paste0(testvar, ":post_detail::", c(1,3,4,5)), "Estimate"]),
  se = c(mA$coeftable[paste0(testvar, ":post_detail::", c(1,3,4,5)), "Std. Error"],
         mB$coeftable[paste0(testvar, ":post_detail::", c(1,3,4,5)), "Std. Error"])
)

csv_stats <- data.frame(
  panel = c("A", "B"),
  estimator = c("FE-OLS", "PPML"),
  N = c(stats::nobs(mA), stats::nobs(mB)),
  R2 = c(safe_wr2(mA), safe_pr2(mB)),
  y_mean = c(ysA["mean"], ysB["mean"]),
  y_sd = c(ysA["sd"], ysB["sd"])
)

write.csv(csv_coef, file = "output/table_IV_col3_friend_coefs.csv", row.names = FALSE)
write.csv(csv_stats, file = "output/table_IV_col3_friend_stats.csv", row.names = FALSE)

message("Wrote: ", normalizePath("output/table_IV_col3_friend_coefs.csv", winslash = "/"))
message("Wrote: ", normalizePath("output/table_IV_col3_friend_stats.csv", winslash = "/"))

# --------------------------------------------
# PNG output
# --------------------------------------------

png_panelA <- "output/table_IV_col3_panelA_native.png"
png_panelB <- "output/table_IV_col3_panelB_native.png"

# Extract raw coefficients for display
get_coef_val <- function(mod, period) {
  term <- paste0(testvar, ":post_detail::", period)
  if (term %in% rownames(mod$coeftable)) {
    list(
      coef = mod$coeftable[term, "Estimate"],
      se = mod$coeftable[term, "Std. Error"],
      p = mod$coeftable[term, grep("Pr\\(", colnames(mod$coeftable))[1]]
    )
  } else {
    list(coef = NA, se = NA, p = NA)
  }
}

# Significance stars
sig_star <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

# Panel A coefficients
a1 <- get_coef_val(mA, 1)
a3 <- get_coef_val(mA, 3)
a4 <- get_coef_val(mA, 4)
a5 <- get_coef_val(mA, 5)

# Panel B coefficients
b1 <- get_coef_val(mB, 1)
b3 <- get_coef_val(mB, 3)
b4 <- get_coef_val(mB, 4)
b5 <- get_coef_val(mB, 5)

# ============================================
# PNG for Panel A only
# ============================================

png(
  png_panelA,
  width = 1200,
  height = 900,
  res = 150
)

par(mar = c(1, 1, 1, 1), family = "sans")
plot.new()

# Title
text(0.5, 0.98, "Table IV Column (3): Debt/Revenue", font = 2, cex = 1.6)
text(0.5, 0.95, "Panel A: Maintenance & Depreciation (FE-OLS)", font = 2, cex = 1.3)

# Top line
segments(0.08, 0.92, 0.92, 0.92, lwd = 3)

y_pos <- 0.88

# Coefficients
text(0.08, y_pos, "moodyleverage × 1924-1926", adj = 0, cex = 1.1)
text(0.75, y_pos, sprintf("%.2f%s", a1$coef, sig_star(a1$p)), cex = 1.1)
y_pos <- y_pos - 0.025
text(0.75, y_pos, sprintf("(%.2f)", a1$se), cex = 0.95, col = "gray30")
y_pos <- y_pos - 0.05

text(0.08, y_pos, "moodyleverage × 1929-1933", adj = 0, cex = 1.1)
text(0.75, y_pos, sprintf("%.2f%s", a3$coef, sig_star(a3$p)), cex = 1.1)
y_pos <- y_pos - 0.025
text(0.75, y_pos, sprintf("(%.2f)", a3$se), cex = 0.95, col = "gray30")
y_pos <- y_pos - 0.05

text(0.08, y_pos, "moodyleverage × 1934-1938", adj = 0, cex = 1.1)
text(0.75, y_pos, sprintf("%.2f%s", a4$coef, sig_star(a4$p)), cex = 1.1)
y_pos <- y_pos - 0.025
text(0.75, y_pos, sprintf("(%.2f)", a4$se), cex = 0.95, col = "gray30")
y_pos <- y_pos - 0.05

text(0.08, y_pos, "moodyleverage × 1941-1943", adj = 0, cex = 1.1)
text(0.75, y_pos, sprintf("%.2f%s", a5$coef, sig_star(a5$p)), cex = 1.1)
y_pos <- y_pos - 0.025
text(0.75, y_pos, sprintf("(%.2f)", a5$se), cex = 0.95, col = "gray30")
y_pos <- y_pos - 0.05

# Controls and stats
segments(0.08, y_pos, 0.92, y_pos, lwd = 2)
y_pos <- y_pos - 0.04

text(0.08, y_pos, "City FE", adj = 0, cex = 1.0)
text(0.75, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.035

text(0.08, y_pos, "Year FE", adj = 0, cex = 1.0)
text(0.75, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.035

text(0.08, y_pos, "1930 Pop x Year", adj = 0, cex = 1.0)
text(0.75, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.035

text(0.08, y_pos, "∆1920-30 Pop x Year", adj = 0, cex = 1.0)
text(0.75, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.035

text(0.08, y_pos, "Revenue", adj = 0, cex = 1.0)
text(0.75, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.035

text(0.08, y_pos, "Region x Year", adj = 0, cex = 1.0)
text(0.75, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.045

segments(0.08, y_pos, 0.92, y_pos, lwd = 2)
y_pos <- y_pos - 0.04

text(0.08, y_pos, "R-sq (within)", adj = 0, cex = 1.0)
text(0.75, y_pos, sprintf("%.2f", safe_wr2(mA)), cex = 1.0)
y_pos <- y_pos - 0.035

text(0.08, y_pos, "N", adj = 0, cex = 1.0)
text(0.75, y_pos, format(stats::nobs(mA), big.mark = ","), cex = 1.0)
y_pos <- y_pos - 0.035

text(0.08, y_pos, "Mean(y)", adj = 0, cex = 1.0)
text(0.75, y_pos, sprintf("%.2f", ysA["mean"]), cex = 1.0)
y_pos <- y_pos - 0.035

text(0.08, y_pos, "SD(y)", adj = 0, cex = 1.0)
text(0.75, y_pos, sprintf("%.2f", ysA["sd"]), cex = 1.0)
y_pos <- y_pos - 0.04

# Bottom line
segments(0.08, y_pos, 0.92, y_pos, lwd = 3)
y_pos <- y_pos - 0.03

# Note
text(0.5, y_pos - 0.02, "Standard errors (clustered at city level) in parentheses. *** p<0.01, ** p<0.05, * p<0.10", cex = 0.85, font = 3)

dev.off()
message("Wrote: ", normalizePath(png_panelA, winslash = "/"))

# ============================================
# PNG for Panel B only
# ============================================

png(
  png_panelB,
  width = 1200,
  height = 900,
  res = 150
)

par(mar = c(1, 1, 1, 1), family = "sans")
plot.new()

# Title
text(0.5, 0.98, "Table IV Column (3): Debt/Revenue", font = 2, cex = 1.6)
text(0.5, 0.95, "Panel B: Capital Outlay (PPML)", font = 2, cex = 1.3)

# Top line
segments(0.08, 0.92, 0.92, 0.92, lwd = 3)

y_pos <- 0.88

# Coefficients
text(0.08, y_pos, "moodyleverage × 1924-1926", adj = 0, cex = 1.1)
text(0.75, y_pos, sprintf("%.2f%s", b1$coef, sig_star(b1$p)), cex = 1.1)
y_pos <- y_pos - 0.025
text(0.75, y_pos, sprintf("(%.2f)", b1$se), cex = 0.95, col = "gray30")
y_pos <- y_pos - 0.05

text(0.08, y_pos, "moodyleverage × 1929-1933", adj = 0, cex = 1.1)
text(0.75, y_pos, sprintf("%.2f%s", b3$coef, sig_star(b3$p)), cex = 1.1)
y_pos <- y_pos - 0.025
text(0.75, y_pos, sprintf("(%.2f)", b3$se), cex = 0.95, col = "gray30")
y_pos <- y_pos - 0.05

text(0.08, y_pos, "moodyleverage × 1934-1938", adj = 0, cex = 1.1)
text(0.75, y_pos, sprintf("%.2f%s", b4$coef, sig_star(b4$p)), cex = 1.1)
y_pos <- y_pos - 0.025
text(0.75, y_pos, sprintf("(%.2f)", b4$se), cex = 0.95, col = "gray30")
y_pos <- y_pos - 0.05

text(0.08, y_pos, "moodyleverage × 1941-1943", adj = 0, cex = 1.1)
text(0.75, y_pos, sprintf("%.2f%s", b5$coef, sig_star(b5$p)), cex = 1.1)
y_pos <- y_pos - 0.025
text(0.75, y_pos, sprintf("(%.2f)", b5$se), cex = 0.95, col = "gray30")
y_pos <- y_pos - 0.05

# Controls and stats
segments(0.08, y_pos, 0.92, y_pos, lwd = 2)
y_pos <- y_pos - 0.04

text(0.08, y_pos, "City FE", adj = 0, cex = 1.0)
text(0.75, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.035

text(0.08, y_pos, "Year FE", adj = 0, cex = 1.0)
text(0.75, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.035

text(0.08, y_pos, "1930 Pop x Year", adj = 0, cex = 1.0)
text(0.75, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.035

text(0.08, y_pos, "∆1920-30 Pop x Year", adj = 0, cex = 1.0)
text(0.75, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.035

text(0.08, y_pos, "Revenue", adj = 0, cex = 1.0)
text(0.75, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.035

text(0.08, y_pos, "Region x Year", adj = 0, cex = 1.0)
text(0.75, y_pos, "✓", cex = 1.2)
y_pos <- y_pos - 0.045

segments(0.08, y_pos, 0.92, y_pos, lwd = 2)
y_pos <- y_pos - 0.04

text(0.08, y_pos, "R-sq (pseudo)", adj = 0, cex = 1.0)
text(0.75, y_pos, sprintf("%.2f", safe_pr2(mB)), cex = 1.0)
y_pos <- y_pos - 0.035

text(0.08, y_pos, "N", adj = 0, cex = 1.0)
text(0.75, y_pos, format(stats::nobs(mB), big.mark = ","), cex = 1.0)
y_pos <- y_pos - 0.035

text(0.08, y_pos, "Mean(y)", adj = 0, cex = 1.0)
text(0.75, y_pos, sprintf("%.2f", ysB["mean"]), cex = 1.0)
y_pos <- y_pos - 0.035

text(0.08, y_pos, "SD(y)", adj = 0, cex = 1.0)
text(0.75, y_pos, sprintf("%.2f", ysB["sd"]), cex = 1.0)
y_pos <- y_pos - 0.04

# Bottom line
segments(0.08, y_pos, 0.92, y_pos, lwd = 3)
y_pos <- y_pos - 0.03

# Note
text(0.5, y_pos - 0.02, "Standard errors (clustered at city level) in parentheses. *** p<0.01, ** p<0.05, * p<0.10", cex = 0.85, font = 3)

dev.off()
message("Wrote: ", normalizePath(png_panelB, winslash = "/"))
