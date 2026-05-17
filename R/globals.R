# Column metadata, brand palette, dataset path. Shared by data loading,
# plot builders, and every module — single source of truth so renaming a
# column or rebranding the palette is a one-file edit.

NUMERICAL_COLS <- c(
  "age",
  "study_hours_per_day",
  "social_media_hours",
  "netflix_hours",
  "attendance_percentage",
  "sleep_hours",
  "exercise_frequency",
  "mental_health_rating",
  "exam_score",
  "grade"
)

CATEGORICAL_COLS <- c(
  "gender",
  "part_time_job",
  "diet_quality",
  "parental_education_level",
  "internet_quality",
  "extracurricular_participation"
)

# Tuned for legibility against the Darkly card background (#222831).
# First entry is the default single-series fill on histograms / scatter.
BRAND_PALETTE <- c(
  "#18BC9C", "#3498DB", "#F39C12",
  "#E74C3C", "#8E44AD", "#7F8C8D"
)

DATA_PATH <- file.path("data", "student_habits_performance.csv")

#' Interpolated ramp for arbitrary-cardinality categorical fills.
make_palette <- function(n) {
  grDevices::colorRampPalette(BRAND_PALETTE)(n)
}
