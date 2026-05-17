# One-shot installer for local R setups that don't use renv.
# Installs only packages not already present; running again is a no-op.

required <- c(
  "shiny", "bslib", "dplyr", "readr", "DT",
  "plotly", "ggplot2", "thematic", "rlang"
)

missing <- setdiff(required, rownames(installed.packages()))
if (length(missing) > 0) {
  install.packages(missing, repos = "https://cloud.r-project.org")
} else {
  message("All required packages already installed.")
}
