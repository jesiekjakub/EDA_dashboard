# Dataset loading + the exam_score -> grade derivation.
#
# load_dataset() is called from inside a reactive() so a missing CSV
# surfaces as a friendly card per plot instead of crashing the worker.
# The grade derivation is a pure helper so it stays testable without
# spinning up Shiny.

REQUIRED_COLS <- c(
  "student_id", "age", "gender", "study_hours_per_day", "social_media_hours",
  "netflix_hours", "part_time_job", "attendance_percentage", "sleep_hours",
  "diet_quality", "exercise_frequency", "parental_education_level",
  "internet_quality", "mental_health_rating", "extracurricular_participation",
  "exam_score"
)

#' Map an exam score (0-100) onto the Polish 6-point grading scale.
#'
#' Boundaries chosen to match the source dataset's documented grading
#' convention. Anything outside [0, 100] returns NA so downstream filters
#' don't silently include malformed rows.
derive_grade <- function(exam_score) {
  dplyr::case_when(
    exam_score <= 50                   ~ 2.0,
    exam_score >  50 & exam_score <= 60 ~ 3.0,
    exam_score >  60 & exam_score <= 70 ~ 3.5,
    exam_score >  70 & exam_score <= 80 ~ 4.0,
    exam_score >  80 & exam_score <= 90 ~ 4.5,
    exam_score >  90                    ~ 5.0,
    TRUE                                ~ NA_real_
  )
}

#' Read the dataset, validate its schema, derive the grade column.
#'
#' Must be invoked inside a reactive context — both file-existence and
#' schema checks use `shiny::validate()`, which only short-circuits cleanly
#' when there's a render function above on the stack.
load_dataset <- function(path = DATA_PATH) {
  shiny::validate(
    shiny::need(
      file.exists(path),
      paste0(
        "Dataset not found at '", path, "'.\n",
        "Download student_habits_performance.csv from Kaggle ",
        "(see data/README.md) and place it in the data/ folder."
      )
    )
  )

  df <- readr::read_csv(path, show_col_types = FALSE)

  missing <- setdiff(REQUIRED_COLS, names(df))
  shiny::validate(
    shiny::need(
      length(missing) == 0,
      paste0(
        "Dataset is missing required columns: ",
        paste(missing, collapse = ", "),
        ".\nSee data/README.md for the expected schema."
      )
    )
  )

  df |>
    dplyr::mutate(grade = derive_grade(.data$exam_score)) |>
    dplyr::select(-"student_id")
}
