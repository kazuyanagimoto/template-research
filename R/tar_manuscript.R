# Manuscript sub-plan: render the single-file Typst manuscript when any
# source file or upstream data target changes.
#
# The dependency list is DERIVED from manuscript/_setup.R, never hand-written.
# A hand-maintained list silently rots: forget to add a target the manuscript
# reads, and tar_make() reports the project up to date while manuscript.pdf
# keeps the old numbers. tar_outdated() does not warn about it either, because
# from targets' point of view nothing is out of date.

# Names of the targets the manuscript loads, read out of manuscript/_setup.R by
# walking every tar_load()/tar_read() call in it. Sourced fresh on each
# tar_make(), so adding a target to _setup.R registers it as a dependency here
# with no second edit.
manuscript_targets <- function(file = here::here("manuscript", "_setup.R")) {
  if (!file.exists(file)) {
    return(character())
  }
  found <- character()
  walk <- function(x) {
    if (!is.call(x)) {
      return(invisible(NULL))
    }
    fn <- x[[1]]
    # match tar_load(), targets::tar_load(), and the tar_read() forms
    name <- if (is.name(fn)) {
      as.character(fn)
    } else if (is.call(fn) && as.character(fn[[1]]) %in% c("::", ":::")) {
      as.character(fn[[3]])
    } else {
      ""
    }
    if (name %in% c("tar_load", "tar_read") && length(x) >= 2) {
      found <<- c(found, all.vars(x[[2]]))
    }
    for (i in seq_along(x)) {
      # An empty argument (as in x[i, ]) is the empty symbol. Test it in place:
      # binding it to a variable and then evaluating that variable errors.
      if (identical(x[[i]], quote(expr = ))) {
        next
      }
      el <- x[[i]]
      if (is.call(el)) walk(el)
    }
    invisible(NULL)
  }
  for (expr in parse(file, keep.source = FALSE)) {
    walk(expr)
  }
  # `store` and friends are arguments, not targets: keep only real target names
  setdiff(unique(found), c("store", "script"))
}

tar_manuscript <- tar_plan(
  tar_file(
    manuscript_src,
    list.files(
      here_rel("manuscript"),
      # .R matters: _setup.R holds the target loads and the formatters, so
      # editing it has to rebuild the PDF.
      pattern = "\\.(qmd|yml|tex|typ|bib|lua|R)$",
      recursive = TRUE,
      full.names = TRUE
    )
  ),
  tar_target_raw(
    "manuscript_pdf",
    command = bquote(
      {
        # Bare references register upstream targets as dependencies so the PDF
        # rebuilds when sources or data change.
        manuscript_src
        list(..(lapply(manuscript_targets(), as.name)))
        quarto::quarto_render(here_rel("manuscript", "manuscript.qmd"))
        here_rel("manuscript", "manuscript.pdf")
      },
      splice = TRUE
    ),
    format = "file"
  )
)
