library(targets)
library(tarchetypes)
suppressPackageStartupMessages(library(dplyr))

options(
  dplyr.summarise.inform = FALSE,
  readr.show_col_types = FALSE
)

tar_config_set(
  store = here::here("_targets"),
  script = here::here("_targets.R")
)

tar_option_set(
  packages = c("dplyr", "tidyr", "forcats", "stringr", "readr", "ggplot2")
)

# Source everything in R/. Each R/tar_*.R defines a named tar_plan object
# (a sub-plan) plus the helper functions it uses.
tar_source()
tar_plan(
  tar_figure,
  tar_data,
  tar_analysis,
  tar_manuscript
)
