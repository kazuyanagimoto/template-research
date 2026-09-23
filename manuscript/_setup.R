# Shared setup for the manuscript chapters: pipeline targets, figure helpers,
# number formatters. Every chapter starts with
#   here::i_am("manuscript/_quarto.yml")
#   source(here::here("manuscript", "_setup.R"))
#
# IMPORTANT: this file is the ONLY place the manuscript may call tar_load() or
# tar_read(). R/tar_manuscript.R parses the tar_load()/tar_read() calls below to
# build manuscript_pdf's dependency list, so a target loaded here is guaranteed
# to trigger a rebuild when it changes. A tar_load() hidden in a chapter would
# escape that scan and let the PDF keep stale numbers.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(tinytable)
  library(modelsummary)
})
options(tinytable_html_mathjax = TRUE)

# Pin here() to the project root, not manuscript/, so that working-dir changes
# from editor renders or quarto book builds resolve identically.
here::i_am("manuscript/_quarto.yml")
knitr::opts_knit$set(root.dir = here::here())
targets::tar_config_set(
  store = here::here("_targets"),
  script = here::here("_targets.R")
)

targets::tar_load(c(
  penguins_clean,
  analysis_body_mass,
  analysis_flipper_fit
))
invisible(list2env(targets::tar_read(fn_figure), .GlobalEnv))
theme_set(theme_proj())

# ---- number formatters ------------------------------------------------------
# Inline numbers in prose go through these, so rounding is consistent and no
# empirical number is ever typed as a literal.

f1 <- function(x) sprintf("%.1f", x)
f2 <- function(x) sprintf("%.2f", x)
f3 <- function(x) sprintf("%.3f", x)
pct <- function(x) sprintf("%.0f%%", 100 * x)

# Significance stars for modelsummary(), as a named vector of p thresholds.
STARS <- c("*" = 0.1, "**" = 0.05, "***" = 0.01)
