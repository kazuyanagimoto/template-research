# Project-root-relative paths for tar_file targets, so the targets store
# stays portable across machines.
here_rel <- function(...) {
  fs::path_rel(here::here(...))
}
