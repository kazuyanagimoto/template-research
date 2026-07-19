# Project conventions

## Pipeline (`_targets.R`, `R/`)

- `_targets.R` composes named sub-plans defined in `R/tar_*.R` (`tar_figure`, `tar_data`, `tar_analysis`, `tar_manuscript`). Each file holds one `tar_plan()` object plus the helper functions it uses.
- The pipeline produces **data objects only** (cleaned data, estimates, plot-ready summaries). Figures are built inline in Quarto with `tar_read()` + ggplot; never register a figure as a target or write it to disk.
- Raw files in `data/` are tracked with `tar_file` / `tar_file_read` using `here_rel()` so the store stays portable. Processed data are never saved as files.
- Run with `targets::tar_make()`.

## Environment

- R packages are managed by `rv` (`rproject.toml` + `rv.lock`), activated via `.Rprofile` -> `rv/scripts/`. Add packages with `rv add <pkg>` (or `.rv$add("<pkg>")` in R), not `install.packages()`.
- The R version is pinned in `rproject.toml` and installed with `rig`.

## Notes (`notes/`)

- One folder per round of trial and error: `notes/NN-name/{index.qmd, code/, output/, data}`. `output/` is gitignored; `data` is a symlink to `notes/data/`, the single home of note-stage datasets.
- Notes read pipeline targets via `store <- here::here("_targets")` and `tar_read(..., store = store)`, and load figure helpers with `list2env(tar_read(fn_figure, store = store), globalenv())`.
- Note-only computation stays in the note (`code/`, cached to `output/`); it is never added to the main plan. Promote code into `R/tar_*.R` only once the result is established.

## Manuscript and slides

- `manuscript/` is its own Quarto book project; `manuscript.qmd` is the single-file Typst build (econ-manuscript extension). Chapters pin paths with `here::i_am("manuscript/_quarto.yml")` and read inputs exclusively with `tar_load()`/`tar_read()`. The manuscript tracks the live pipeline.
- `slides/` is its own Quarto project (`slides/_quarto.yml`, `type: default`, `execute-dir: file`), parallel to `manuscript/`, so the shared `slides/_extensions` (Touying/Typst) and `slides/_quarto.yml` config apply to every deck. The repo-root website project excludes it via `.quartoignore`. Render a deck with `quarto render slides/YYMMDD_venue/index.qmd`, or the whole project with `quarto render slides`.
- Each deck is a folder `slides/YYMMDD_venue/{index.qmd, code/, output/, data}`, structured like a note. A deck is a **frozen snapshot**: it never uses `tar_load`/`tar_read`. It carries the theme, data, and results it needs (`code/`, `output/`, or the `data -> ../data` symlink to `slides/data/`) so it compiles identically regardless of how the pipeline later evolves. With `execute-dir: file`, use paths relative to the deck folder (`source("code/setup.R")`, `read_csv("data/...")`).
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
