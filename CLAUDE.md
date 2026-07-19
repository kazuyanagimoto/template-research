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

- `manuscript/` is its own Quarto book project; `manuscript.qmd` is the single-file Typst build (econ-manuscript extension). Chapters pin paths with `here::i_am("manuscript/_quarto.yml")` and read inputs exclusively with `tar_load()`/`tar_read()`.
- `slides/` holds dated decks (`YYMMDD_venue.qmd`, Touying + clean Typst theme) that likewise only consume targets.
- No hard-coded empirical numbers in prose, captions, or annotations; compute them in R and interpolate.

## Writing and style

- `references.bib` is Zotero-managed; never hand-edit it.
- Quarto + R style follows the machine-wide `quarto-r` skill: English plot text, `tinytable` (no `kable`), hash-pipe chunk headers, one sentence per line in prose, no em-dashes.
- Code comments and docstrings are in English.
