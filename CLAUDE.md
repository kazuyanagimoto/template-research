# Project conventions

## Pipeline (`_targets.R`, `R/`)

- `_targets.R` composes named sub-plans defined in `R/tar_*.R` (`tar_figure`, `tar_data`, `tar_analysis`, `tar_manuscript`). Each file holds one `tar_plan()` object plus the helper functions it uses.
- The pipeline produces **data objects only** (cleaned data, estimates, plot-ready summaries). Figures are built inline in Quarto with ggplot; never register a figure as a target or write it to disk. `manuscript/` is the only consumer that reads the store with `tar_read()`/`tar_load()`.
- Raw files in `data/` are tracked with `tar_file` / `tar_file_read` using `here_rel()` so the store stays portable. Processed data are never saved as files.
- Run with `targets::tar_make()`.

## Environment

- R packages are managed by `rv` (`rproject.toml` + `rv.lock`), activated via `.Rprofile` -> `rv/scripts/`. Add packages with `rv add <pkg>` (or `.rv$add("<pkg>")` in R), not `install.packages()`.
- The R version is pinned in `rproject.toml` and installed with `rig`.

## Notes (`notes/`)

- One folder per round of trial and error: `notes/NN-name/{index.qmd, code/, output/, data}`. `data` is a symlink to `notes/data/`, the single home of note-stage datasets.
- A note is a **frozen snapshot**, like a deck: it never uses `tar_load`/`tar_read`, and nothing in `notes/` loads `targets`. The setup chunk is just `source(here::here("notes", "NN-name", "code", "setup.R"))` plus `theme_set(theme_note())`. The notes website renders from the repo root, so note-local paths go through `here::here()`.
- The freeze has two halves. **Computation**: numbered scripts `code/NN_*.R` are the only place raw data is read, and they write `output/*.csv`; the qmd reads those CSVs (`O` + `rd()` in `setup.R`) and computes nothing. Dropping `tar_read` is not enough on its own, because a setup that reads `data/` is still on live data. **Presentation**: `code/setup.R` carries the frozen theme (`theme_note()`), palettes, `scale_*()` helpers, and table helpers.
- So `code/` is the record and `output/` is a regenerable cache; `output/` is gitignored and `setup.R` rebuilds it if a CSV is missing. Run the scripts by hand (`Rscript notes/NN-name/code/01_*.R`) when inputs change.
- Note-only computation is never added to the main plan. Promote code into `R/tar_*.R` only once the result is established; the note keeps its frozen copy.

## Manuscript and slides

- `manuscript/` is its own Quarto book project; `manuscript.qmd` is the single-file Typst build (econ-manuscript extension). The manuscript tracks the live pipeline.
- **`manuscript/_setup.R` is the only place the manuscript may call `tar_load()`/`tar_read()`.** Every chapter begins with `here::i_am("manuscript/_quarto.yml")` then `source(here::here("manuscript", "_setup.R"))`, which loads the targets, the figure helpers, and the number formatters. `R/tar_manuscript.R` parses `_setup.R` to derive `manuscript_pdf`'s dependency list, so adding a target there is enough to make the PDF rebuild when it changes. A `tar_load()` hidden in a chapter escapes that scan and leaves the PDF silently stale, which `tar_outdated()` will not report.
- `slides/` is its own Quarto project (`slides/_quarto.yml`, `type: default`, `execute-dir: file`), parallel to `manuscript/`, so the shared `slides/_extensions` (Touying/Typst) and `slides/_quarto.yml` config apply to every deck. The repo-root website project excludes it via `.quartoignore`. Render a deck with `quarto render slides/YYMMDD_venue/index.qmd`, or the whole project with `quarto render slides`.
- Each deck is a folder `slides/YYMMDD_venue/{index.qmd, code/, output/, data}`, structured like a note, and is a **frozen snapshot** on the same terms: it never uses `tar_load`/`tar_read`. It carries the theme, data, and results it needs (`code/`, `output/`, or the `data -> ../data` symlink to `slides/data/`) so it compiles identically regardless of how the pipeline later evolves. With `execute-dir: file`, use paths relative to the deck folder (`source("code/setup.R")`, `read_csv("data/...")`).
- Structure a deck with `#` section dividers and `##` content slides. The clean Typst theme renders a bare `##` (with no preceding `#`) as a section divider, so every deck needs at least one `#`. Inside a slide, `###` is a subheading; math in table cells uses the `theme_mitex` finalizer; `cetz` diagrams go in a raw ```` ```{=typst} ```` block.
- No hard-coded empirical numbers in prose, captions, or annotations; compute them in R and interpolate.

## Writing and style

- `references.bib` is Zotero-managed; never hand-edit it.
- Code comments and docstrings are in English.
- No em-dashes anywhere (prose, captions, comments, strings). Use commas, parentheses, or rewrite.
- Reserve "significant"/"significantly" for statistical significance only; otherwise use "substantial", "large", "marked", etc.

### R code

- Format R with [air](https://posit-dev.github.io/air/) (`air format .`); settings are in `air.toml`. The `rv/` scripts are excluded because rv generates them. The air VS Code/Positron extension formats R chunks inside `.qmd` on save using the same `air.toml`.
- Aggregate with `summarize(.by = ...)` (and `mutate/filter(.by = ...)`), not a separate `group_by()`.
- Estimate regressions with `fixest` (`feols`/`feglm`/`fepois`), not `lm`/`glm`; set `vcov` explicitly (`"hetero"` or `~cluster`).

### Quarto (notes, slides, manuscript)

- All figure text is English: `labs()`, `scale_*(name = ...)`, axis/legend/facet labels, and `#| fig-cap`. Table captions (`#| tbl-cap`, `tt(caption = ...)`) match the surrounding prose language.
- Never hard-code empirical numbers in prose, captions, or `annotate()`. Compute them in R and interpolate with inline `` `r ...` `` / `sprintf()`.
- Tables use `tinytable` (`tt()`, or `modelsummary(..., output = "tinytable")`), never `knitr::kable()`. In-cell math is LaTeX (`$\sigma$`); set `options(tinytable_html_mathjax = TRUE)` for HTML.
- R chunk options use the hash-pipe form (`#| label:`), not inline `{r, opt=val}`. Use cross-ref prefixes (`fig-*`, `tbl-*`, `sec-*`); slides use `plot-*` / `table-*` to suppress auto-captions.
- In `geom_point`, map the color variable to `shape` too (and `linetype` for lines) so figures survive grayscale and color-blindness; keep one merged legend by giving the scales the same `name`. Prefer the legend inside an empty panel corner.
- Prose uses one sentence per line (semantic line breaks); do not hard-wrap a sentence.
- On slides, use bold sparingly: at most one punchline per slide, or as a structural label; not for terminology or numbers.
