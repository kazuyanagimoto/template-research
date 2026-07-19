# Data sub-plan: raw file targets + cleaning helpers.
#
# Conventions:
# - Raw files live in data/ (gitignored except .gitkeep) and are tracked with
#   tar_file / tar_file_read so the pipeline rebuilds when a file changes.
# - Processed data are NOT written to disk; they exist only as targets in the
#   store (_targets/) and are consumed downstream with tar_read()/tar_load().

tar_data <- tar_plan(
  # Template for raw data tracked from data/:
  # tar_file_read(
  #   survey_raw,
  #   here_rel("data", "survey.csv"),
  #   readr::read_csv(!!.x)
  # ),
  # survey = clean_survey(survey_raw),

  # Working example with a built-in dataset so tar_make() succeeds on a fresh
  # clone. Replace with your own data targets.
  penguins_clean = clean_penguins(datasets::penguins)
)

# ---- cleaning helpers -------------------------------------------------------

clean_penguins <- function(data) {
  data |>
    tidyr::drop_na(body_mass, sex) |>
    mutate(
      sex = factor(
        if_else(sex == "female", "Female", "Male"),
        levels = c("Female", "Male")
      ),
      body_mass_kg = body_mass / 1000
    )
}
