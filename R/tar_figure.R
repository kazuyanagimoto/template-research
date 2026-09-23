# Figure-helper sub-plan: a single target `fn_figure` bundling the ggplot
# theme, accent colors, palettes, and table helpers.
#
# The manuscript loads everything at once with
#   list2env(targets::tar_read(fn_figure), envir = globalenv())
# and is the only consumer: notes and slides are frozen snapshots that keep
# their own copy of whatever they need in their code/setup.R.

tar_figure <- tar_plan(
  fn_figure = list(
    theme_proj = theme_proj,
    theme_mitex = theme_mitex,
    notes_text = notes_text,
    color_accent = color_accent,
    color_accent2 = color_accent2,
    color_accent3 = color_accent3,
    pal_sex = pal_sex,
    lty_sex = lty_sex,
    shp_sex = shp_sex,
    scale_sex = scale_sex,
    pal_species = pal_species,
    lty_species = lty_species,
    shp_species = shp_species,
    scale_species = scale_species
  )
)

# ---- theme ------------------------------------------------------------------

theme_proj <- function(
  font_title = "Roboto Condensed",
  font_text = "Roboto Condensed Light",
  size_base = 11
) {
  ggplot2::theme_classic(base_family = font_text, base_size = size_base) +
    ggplot2::theme(
      # Right margin prevents the last x-axis tick label (e.g., 2025 on
      # year-axis plots) from being clipped by the Typst image bbox.
      plot.margin = ggplot2::margin(t = 5, r = 30, b = 5, l = 5),
      plot.title = ggplot2::element_text(
        size = size_base,
        face = "bold",
        family = font_title
      ),
      plot.subtitle = ggplot2::element_text(
        size = size_base,
        face = "plain",
        family = font_text
      ),
      plot.caption = ggplot2::element_text(
        size = size_base * 0.6,
        color = "grey50",
        face = "plain",
        family = font_text,
        margin = ggplot2::margin(t = 10)
      ),
      legend.position = "none",
      legend.title = ggplot2::element_blank(),
      legend.key = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(
        size = size_base * 0.9,
        family = font_text,
        face = "plain"
      ),
      axis.line = ggplot2::element_line(linewidth = 0.3),
      axis.ticks = ggplot2::element_line(linewidth = 0.3),
      axis.title = ggplot2::element_text(
        family = font_text,
        face = "plain",
        size = size_base
      ),
      axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = 5)),
      axis.text = ggplot2::element_text(
        family = font_text,
        face = "plain",
        size = size_base * 0.9
      ),
      strip.background = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(
        size = size_base * 0.95,
        hjust = 0,
        family = font_title,
        face = "bold"
      )
    )
}

# ---- colors and palettes ----------------------------------------------------

color_accent <- "#107895"
color_accent2 <- "#9a2515"
color_accent3 <- "#e64173"

# One named palette (+ linetype + shape) per recurring categorical variable,
# and a scale_*() helper that applies all three at once so color, linetype,
# and shape merge into a single legend. Add more as the project grows.
pal_sex <- c("Female" = color_accent2, "Male" = color_accent)
lty_sex <- c("Female" = "solid", "Male" = "dashed")
shp_sex <- c("Female" = 16, "Male" = 17)

scale_sex <- function(...) {
  list(
    ggplot2::scale_color_manual(values = pal_sex, ...),
    ggplot2::scale_linetype_manual(values = lty_sex, ...),
    ggplot2::scale_shape_manual(values = shp_sex, ...)
  )
}

pal_species <- c(
  "Adelie" = color_accent,
  "Chinstrap" = color_accent2,
  "Gentoo" = color_accent3
)
lty_species <- c(
  "Adelie" = "solid",
  "Chinstrap" = "dashed",
  "Gentoo" = "dotted"
)
shp_species <- c("Adelie" = 16, "Chinstrap" = 17, "Gentoo" = 15)

scale_species <- function(...) {
  list(
    ggplot2::scale_color_manual(values = pal_species, ...),
    ggplot2::scale_linetype_manual(values = lty_species, ...),
    ggplot2::scale_shape_manual(values = shp_species, ...)
  )
}

# ---- table helpers ----------------------------------------------------------

#' Tinytable finalizer that rewrites `$...$` LaTeX math inside table cells
#' into `#mi(`...`)` so that the mitex Typst package renders it correctly.
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
    return(table)
  }
  x <- tinytable::style_tt(x, finalize = fn)
  x <- tinytable::style_tt(x, i = "notes", fontsize = 0.9)
  x <- tinytable::theme_tt(x, theme = "default")
  return(x)
}

#' Prepend an italicised `Notes:` label to a tinytable footer-notes string,
#' with per-format line spacing (LaTeX / Typst / HTML).
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
