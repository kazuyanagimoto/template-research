# Bridge to the project-root .Rprofile so that rendering from manuscript/
# (a separate Quarto book project whose R session starts here) still
# activates the project's rv library.
local({
  old_wd <- getwd()
  proj_root <- normalizePath("..")
  setwd(proj_root)
  on.exit(setwd(old_wd), add = TRUE)
  if (file.exists(".Rprofile")) sys.source(".Rprofile", envir = globalenv())
})
