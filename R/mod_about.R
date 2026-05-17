# About / methodology tab. Pure UI — no reactive state, so there's no
# accompanying server function. App-level server simply doesn't call it.

about_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    bslib::card(
      bslib::card_header("About this dashboard"),
      bslib::card_body(
        shiny::tags$h4("What it does"),
        shiny::tags$p(
          "Three analytical views over a tabular dataset of student ",
          "lifestyle and academic outcomes:"
        ),
        shiny::tags$ul(
          shiny::tags$li(
            shiny::tags$strong("Overview & Distribution"),
            " — summary KPIs, the full data table, and per-column ",
            "distributions for both numeric and categorical attributes."
          ),
          shiny::tags$li(
            shiny::tags$strong("Numerical Relationship"),
            " — Pearson correlation matrix, scatter and 2D-density ",
            "between any two numeric attributes, and a one-vs-all ",
            "correlation ranking. Range sliders propagate to every ",
            "plot on the tab."
          ),
          shiny::tags$li(
            shiny::tags$strong("Mixed-Type Relationship"),
            " — joint-count heatmap of any two categorical attributes, ",
            "and violin plots of any numeric attribute split by a ",
            "categorical one."
          )
        ),
        shiny::tags$h4("Methodology notes", class = "mt-4"),
        shiny::tags$ul(
          shiny::tags$li(
            "Correlations are linear (Pearson). Non-monotonic ",
            "relationships will look uncorrelated even if a strong ",
            "non-linear dependency exists — eyeball the scatter ",
            "before reading the heatmap as gospel."
          ),
          shiny::tags$li(
            "The 2D density plot uses Plotly's ",
            shiny::tags$code("histogram2dcontour"),
            " with heatmap coloring — it's a binned approximation, ",
            "not a true kernel-density estimate."
          ),
          shiny::tags$li(
            "Violin plots show the kernel-density estimate of the ",
            "distribution within each category, with the median ",
            "(box) and mean (line) overlaid."
          ),
          shiny::tags$li(
            "The ",
            shiny::tags$code("grade"),
            " column is derived from ",
            shiny::tags$code("exam_score"),
            " on a 6-point Polish scale (2.0, 3.0, 3.5, 4.0, 4.5, 5.0) ",
            "and is treated as a numeric attribute throughout."
          )
        ),
        shiny::tags$h4("Data source", class = "mt-4"),
        shiny::tags$p(
          "Dataset: ",
          shiny::tags$a(
            href   = "https://www.kaggle.com/datasets/jayaantanaath/student-habits-vs-academic-performance",
            "Student Habits vs Academic Performance",
            target = "_blank",
            rel    = "noopener"
          ),
          " on Kaggle. Drop the CSV at ",
          shiny::tags$code("data/student_habits_performance.csv"),
          " before launching."
        )
      )
    )
  )
}
