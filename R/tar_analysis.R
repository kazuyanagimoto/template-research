# Analysis sub-plan: plot-ready data for notes/slides/manuscript.
#
# Conventions:
# - Targets return data objects (summary tables, model estimates), never
#   figures. Figures are built inline in Quarto documents with ggplot on top
#   of these targets, so that formats (fonts, themes) stay flexible.
# - Each analysis_* target is produced by a fct_*() helper defined below.

tar_analysis <- tar_plan(
  analysis_body_mass = fct_body_mass(penguins_clean),
  analysis_flipper_fit = fct_flipper_fit(penguins_clean)
)

# ---- analysis helpers -------------------------------------------------------

# Mean body mass by species and sex, with counts for inline reporting
fct_body_mass <- function(data) {
  data |>
    summarize(
      n = n(),
      mean_kg = mean(body_mass_kg),
      sd_kg = sd(body_mass_kg),
      .by = c(species, sex)
    )
}

# Linear fit of body mass on flipper length, by species.
# Returns a list: $coef for tables, $pred for plot-ready fitted lines.
fct_flipper_fit <- function(data) {
  fits <- data |>
    tidyr::nest(.by = species) |>
    mutate(fit = lapply(data, \(d) lm(body_mass ~ flipper_len, data = d)))

  coef <- fits |>
    mutate(
      intercept = vapply(fit, \(m) coef(m)[1], numeric(1)),
      slope = vapply(fit, \(m) coef(m)[2], numeric(1)),
      r2 = vapply(fit, \(m) summary(m)$r.squared, numeric(1))
    ) |>
    select(species, intercept, slope, r2)

  pred <- fits |>
    mutate(
      pred = mapply(
        \(m, d) {
          grid <- data.frame(flipper_len = seq(
            min(d$flipper_len), max(d$flipper_len),
            length.out = 50
          ))
          grid$body_mass <- predict(m, newdata = grid)
          grid
        },
        fit, data,
        SIMPLIFY = FALSE
      )
    ) |>
    select(species, pred) |>
    tidyr::unnest(pred)

  list(coef = coef, pred = pred)
}
