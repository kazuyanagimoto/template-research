# Manuscript sub-plan: render the single-file Typst manuscript when any
# source file or upstream data target changes.

tar_manuscript <- tar_plan(
  tar_file(
    manuscript_src,
    list.files(
      here_rel("manuscript"),
      pattern = "\\.(qmd|yml|tex|typ|bib|lua)$",
      recursive = TRUE,
      full.names = TRUE
    )
  ),
  tar_file(
    manuscript_pdf,
    {
      # Bare references register upstream targets as dependencies so the PDF
      # rebuilds when sources or data change.
      manuscript_src
      list(fn_figure, penguins_clean, analysis_body_mass, analysis_flipper_fit)
      quarto::quarto_render(here_rel("manuscript", "manuscript.qmd"))
      here_rel("manuscript", "manuscript.pdf")
    }
  )
)
