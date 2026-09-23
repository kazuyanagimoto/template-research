#!/usr/bin/env Rscript
# Note-stage computation for notes/01-example/index.qmd.
#
# Every table the note shows is computed here and written to output/ as a CSV;
# figures are drawn in the qmd from those CSVs. This is what freezes the note:
# the qmd never recomputes anything and never reads data/, so re-rendering it
# next year reproduces the same numbers. Run it by hand when the inputs change:
#   Rscript notes/01-example/code/01_body_mass.R
#
# output/ is gitignored because it is fully regenerable from this script, which
# is committed. That is the record, not the CSV.

suppressPackageStartupMessages({
  library(dplyr)
  library(here)
})

O <- here("notes", "01-example", "output")
dir.create(O, showWarnings = FALSE, recursive = TRUE)

# A real note reads raw inputs from notes/data/ (via the folder's `data`
# symlink), e.g. readr::read_csv(here("notes", "data", "my_extract.csv")).
# Here we use a built-in dataset so the template runs on a fresh clone.
penguins <- datasets::penguins |>
  tidyr::drop_na(body_mass, sex) |>
  mutate(
    sex = factor(
      if_else(sex == "female", "Female", "Male"),
      levels = c("Female", "Male")
    ),
    body_mass_kg = body_mass / 1000
  )

readr::write_csv(penguins, file.path(O, "penguins.csv"))

# Mean body mass by species and sex, with counts for inline reporting.
penguins |>
  summarize(
    n = n(),
    mean_kg = mean(body_mass_kg),
    sd_kg = sd(body_mass_kg),
    .by = c(species, sex)
  ) |>
  readr::write_csv(file.path(O, "body_mass.csv"))
