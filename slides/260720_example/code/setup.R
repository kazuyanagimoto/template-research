# Frozen setup for this deck.
#
# Slides are self-contained snapshots: unlike the manuscript, a deck never
# reads the live pipeline with tar_load(). Copy whatever theme, palettes,
# data, and results you need into this folder (code/, output/, or the shared
# data/ symlink) so the deck compiles identically forever, no matter how the
# main pipeline in R/ later evolves. Prepare data here; make figures in the qmd.

library(dplyr)
library(ggplot2)
library(tinytable)

# ---- theme (frozen copy) ----------------------------------------------------

color_accent <- "#107895"
color_accent2 <- "#9a2515"

theme_slide <- function(size_base = 18) {
  theme_classic(base_family = "Roboto Condensed Light", base_size = size_base) +
    theme(
      plot.margin = margin(t = 5, r = 30, b = 5, l = 5),
      legend.title = element_blank(),
      legend.key = element_blank(),
      axis.line = element_line(linewidth = 0.3),
      axis.ticks = element_line(linewidth = 0.3),
      strip.background = element_blank(),
      strip.text = element_text(hjust = 0, face = "bold")
    )
}

color_accent3 <- "#e64173"

pal_species <- c(
  "Adelie" = color_accent,
  "Chinstrap" = color_accent2,
  "Gentoo" = color_accent3
)
shp_species <- c("Adelie" = 16, "Chinstrap" = 17, "Gentoo" = 15)

scale_species <- function(...) {
  list(
    scale_color_manual(values = pal_species, ...),
    scale_shape_manual(values = shp_species, ...)
  )
}

# ---- data snapshot ----------------------------------------------------------
# In a real deck, read frozen inputs from the shared data via the folder's
# `data` symlink, e.g. readr::read_csv("data/my_snapshot.csv"), or read cached
# artifacts from output/. Here we use a built-in dataset so the template
# renders on a fresh clone.

penguins_snapshot <- datasets::penguins |>
  tidyr::drop_na(body_mass, species, flipper_len)

# ---- tables with math (mitex demo) ------------------------------------------
# theme_mitex rewrites `$...$` LaTeX in table cells into `#mi(`...`)`, which the
# mitex Typst package (imported in the deck header) renders. Registered as the
# default tinytable theme so every tt() in this deck picks it up.

theme_mitex <- function(x, ...) {
  fn <- function(table) {
    if (isTRUE(table@output == "typst")) {
      table@table_string <- gsub(
        "\\$(.*?)\\$",
        "#mi(`\\1`)",
        table@table_string
      )
      table@table_string <- paste0(
        "#align(center)[\n",
        table@table_string,
        "\n]"
      )
    }
    table
  }
  x <- style_tt(x, finalize = fn)
  theme_tt(x, theme = "default")
}

options(
  tinytable_html_mathjax = TRUE,
  tinytable_tt_theme = theme_mitex
)

# Per-species OLS of body mass on flipper length, for the math table.
species_fit <- penguins_snapshot |>
  tidyr::nest(.by = species) |>
  mutate(
    fit = lapply(data, \(d) lm(body_mass ~ flipper_len, data = d)),
    alpha = vapply(fit, \(m) coef(m)[[1]], numeric(1)),
    beta = vapply(fit, \(m) coef(m)[[2]], numeric(1)),
    r2 = vapply(fit, \(m) summary(m)$r.squared, numeric(1))
  ) |>
  select(species, alpha, beta, r2)
