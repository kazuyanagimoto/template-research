# Research Project Template

An opinionated template for empirical research projects built on:

- [`targets`](https://books.ropensci.org/targets/) for pipeline management
- [`rig`](https://github.com/r-lib/rig) + [`rv`](https://github.com/A2-ai/rv) for reproducible R environments (no renv)
- [Quarto](https://quarto.org/) for notes, slides, and the manuscript (Typst PDF)

## Structure

```
.
├── _targets.R          # Pipeline: composes sub-plans from R/tar_*.R
├── R/
│   ├── tar_data.R      # Data sub-plan: raw file targets + cleaning helpers
│   ├── tar_analysis.R  # Analysis sub-plan: plot-ready data targets
│   ├── tar_figure.R    # fn_figure: shared ggplot theme, palettes, table helpers
│   ├── tar_manuscript.R# Renders the manuscript when sources or data change
│   └── utils.R         # here_rel() and other small helpers
├── data/               # Raw data for the main pipeline (gitignored, .gitkeep)
├── notes/              # Trial-and-error notes (Quarto website, local viewing)
│   ├── data/           # Shared home of note-stage datasets (gitignored)
│   └── 01-example/     # One folder per note: index.qmd, code/, output/, data -> ../data
├── slides/             # Own Quarto project; one folder per deck, frozen snapshots
│   ├── _quarto.yml     # Slides project config (shared across decks)
│   ├── _extensions/    # Touying/Typst theme, shared by all decks
│   ├── data/           # Shared home of slide-stage datasets (gitignored)
│   └── 260720_example/ # index.qmd, code/, output/, data -> ../data
├── manuscript/         # Quarto book + single-file Typst manuscript
├── rproject.toml       # rv manifest (R version, repositories, dependencies)
└── references.bib      # Zotero-managed; symlinked into notes/, slides/, manuscript/
```

## Philosophy

1. **Everything flows through the pipeline.**
   `targets` produces *data objects only* (cleaned data, estimates, plot-ready summaries).
   Figures are built inline in Quarto documents with `tar_read()` + ggplot and are never registered as targets or written to disk.
   Processed data are not stored as files; they live in the targets store (`_targets/`).
2. **Notes are the lab bench.**
   Each `notes/NN-name/` folder is one round of trial and error, with its own `code/` and gitignored `output/`.
   Note-stage datasets live once in `notes/data/` and each note reaches them through a `data -> ../data` symlink, so nothing is duplicated.
   When a note produces a solid result, promote the code into `R/tar_*.R`; the note stays behind as the record.
3. **The manuscript consumes targets; slides are frozen snapshots.**
   The manuscript reads the live pipeline with `tar_load`, so it always reflects the current data.
   `slides/` is its own Quarto project (like `manuscript/`), and each deck is a folder like a note that never uses `tar_load`: it carries the theme, data, and results it needs (in `code/`, `output/`, or via the `data -> ../data` symlink), so a talk given a year ago still compiles as it did then.
   Every number in prose is computed inline (`` `r ...` ``), never typed as a literal.

## Getting started

1. Click "Use this template" on GitHub and clone your copy.
2. Pick a project codename ([Andrew Heiss' idea](https://github.com/andrewheiss/testy-turtle)):

   ```r
   codename::codename(seed = 260720, type = "ubuntu")  # seed = date you opened the repo
   ```

   Rename the repo, `name` in `rproject.toml`, and `manuscript/manuscript.qmd` accordingly.
3. Install the R toolchain (once per machine):

   ```sh
   rig add 4.6        # R version pinned in rproject.toml
   brew install rv    # A2-ai/homebrew-tap/rv
   ```

4. Restore the R environment and run the pipeline:

   ```sh
   rv sync
   R -e 'targets::tar_make()'
   ```

   The example pipeline runs on a built-in dataset, so this works before you add any data.
5. Preview the notes site with `quarto preview`, render a deck with `quarto render slides/260720_example/index.qmd`.
6. Copy `.Renviron.example` to `.Renviron` and fill in API keys as needed.

## Replication (for released projects)

1. Restore the R environment with `rv sync`.
2. Place the raw data listed in `data/` (see the paper's data availability statement).
3. Run `R -e 'targets::tar_make()'` to execute the full pipeline, including the manuscript render (`manuscript/manuscript.pdf`).

## Licenses

**Text and figures:** All rights reserved (or the outlet's license terms).

**Code:** MIT License. See [LICENSE](LICENSE).
