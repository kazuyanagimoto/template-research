# Frozen setup for this note.
#
# Notes are self-contained snapshots: unlike the manuscript, a note never reads
# the live pipeline with tar_read(). A note is the record of one round of trial
# and error, so it has to keep saying what it said on the day it was written.
# Copy whatever theme, palettes, data, and results you need into this folder
# (code/, output/, or the shared data/ symlink) so the note renders identically
# forever, no matter how the main pipeline in R/ later evolves. Prepare data
# here; make figures in the qmd.

library(dplyr)
library(ggplot2)
library(tinytable)

# ---- theme (frozen copy) ----------------------------------------------------

color_accent <- "#107895"
color_accent2 <- "#9a2515"
color_accent3 <- "#e64173"

theme_note <- function(
  font_title = "Roboto Condensed",
  font_text = "Roboto Condensed Light",
  size_base = 12
) {
  theme_classic(base_family = font_text, base_size = size_base) +
    theme(
      plot.margin = margin(t = 5, r = 30, b = 5, l = 5),
      plot.title = element_text(
        size = size_base,
        face = "bold",
        family = font_title
      ),
      plot.caption = element_text(
        size = size_base * 0.6,
        color = "grey50",
        family = font_text,
        margin = margin(t = 10)
      ),
      legend.title = element_blank(),
      legend.key = element_blank(),
      legend.text = element_text(size = size_base * 0.9, family = font_text),
      axis.line = element_line(linewidth = 0.3),
      axis.ticks = element_line(linewidth = 0.3),
      axis.text = element_text(size = size_base * 0.9, family = font_text),
      strip.background = element_blank(),
      strip.text = element_text(
        size = size_base * 0.95,
        hjust = 0,
        family = font_title,
        face = "bold"
      )
    )
}

pal_sex <- c("Female" = color_accent2, "Male" = color_accent)
lty_sex <- c("Female" = "solid", "Male" = "dashed")
shp_sex <- c("Female" = 16, "Male" = 17)

scale_sex <- function(...) {
  list(
    scale_color_manual(values = pal_sex, ...),
    scale_linetype_manual(values = lty_sex, ...),
    scale_shape_manual(values = shp_sex, ...)
  )
}

# ---- table helpers (frozen copy) --------------------------------------------

# Prepend an italicised `Notes:` label to a tinytable footer-notes string.
notes_text <- function(text) {
  if (knitr::is_latex_output()) {
    paste0("{\\linespread{1}\\selectfont\\textit{Notes:} ", text, "}")
  } else if (isTRUE(knitr::pandoc_to() == "typst")) {
    paste0("#set par(leading: 0.56em, spacing: 0em); #emph[Notes:] ", text)
  } else {
    paste0(
      "<span style=\"line-height: 1.2;\"><em>Notes:</em> ",
      text,
      "</span>"
    )
  }
}

options(tinytable_html_mathjax = TRUE)

# ---- frozen results ---------------------------------------------------------
# The qmd reads CSVs from output/ and nothing else. The computation lives in
# code/01_body_mass.R, which is where raw data is touched; keeping it out of
# the qmd is what makes the note frozen. Reading data/ from here would put the
# note back on live data and let its findings drift.

O <- here::here("notes", "01-example", "output")
rd <- function(f) readr::read_csv(file.path(O, f), show_col_types = FALSE)

# output/ is gitignored but regenerable, so a fresh clone rebuilds it once.
# Re-run code/01_body_mass.R by hand whenever the inputs change.
if (!file.exists(file.path(O, "body_mass.csv"))) {
  source(here::here("notes", "01-example", "code", "01_body_mass.R"))
}

penguins_snapshot <- rd("penguins.csv") |>
  mutate(sex = factor(sex, levels = names(pal_sex)))

body_mass_summary <- rd("body_mass.csv")
