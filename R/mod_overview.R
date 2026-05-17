# Overview & distribution tab. Inputs: dataset reactive. Outputs:
# four KPI value boxes, a searchable data table, and per-column
# histogram / bar chart cards.

overview_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    bslib::layout_column_wrap(
      width = 1 / 4,
      fill  = FALSE,
      bslib::value_box(
        title    = "Students",
        value    = shiny::textOutput(ns("kpi_n")),
        showcase = shiny::icon("users", class = "fa-2x"),
        theme    = "primary"
      ),
      bslib::value_box(
        title    = "Avg exam score",
        value    = shiny::textOutput(ns("kpi_exam")),
        showcase = shiny::icon("graduation-cap", class = "fa-2x"),
        theme    = "info"
      ),
      bslib::value_box(
        title    = "Avg study (h/day)",
        value    = shiny::textOutput(ns("kpi_study")),
        showcase = shiny::icon("book-open", class = "fa-2x"),
        theme    = "warning"
      ),
      bslib::value_box(
        title    = "Avg sleep (h/day)",
        value    = shiny::textOutput(ns("kpi_sleep")),
        showcase = shiny::icon("moon", class = "fa-2x"),
        theme    = "secondary"
      )
    ),
    bslib::card(
      bslib::card_header("Dataset"),
      bslib::card_body(
        DT::DTOutput(ns("student_table"))
      )
    ),
    bslib::layout_columns(
      col_widths = c(6, 6),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header("Numerical distribution"),
        bslib::card_body(
          bslib::layout_columns(
            col_widths = c(7, 5),
            shiny::selectInput(ns("num_col"), "Attribute",
                               choices  = NUMERICAL_COLS,
                               selected = "exam_score"),
            shiny::sliderInput(ns("num_bins"), "Bins",
                               min = 5, max = 60, value = 24, step = 1)
          ),
          shiny::plotOutput(ns("hist_plot"), height = "340px")
        )
      ),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header("Categorical distribution"),
        bslib::card_body(
          shiny::selectInput(ns("cat_col"), "Attribute",
                             choices  = CATEGORICAL_COLS,
                             selected = "diet_quality"),
          shiny::plotOutput(ns("bar_plot"), height = "340px")
        )
      )
    )
  )
}

overview_server <- function(id, df) {
  shiny::moduleServer(id, function(input, output, session) {

    output$kpi_n <- shiny::renderText({
      format(nrow(df()), big.mark = ",")
    })
    output$kpi_exam <- shiny::renderText({
      sprintf("%.1f", mean(df()$exam_score, na.rm = TRUE))
    })
    output$kpi_study <- shiny::renderText({
      sprintf("%.1f", mean(df()$study_hours_per_day, na.rm = TRUE))
    })
    output$kpi_sleep <- shiny::renderText({
      sprintf("%.1f", mean(df()$sleep_hours, na.rm = TRUE))
    })

    output$student_table <- DT::renderDT({
      DT::datatable(
        df(),
        options = list(
          scrollX    = TRUE,
          scrollY    = "320px",
          pageLength = 10,
          dom        = "tip",
          autoWidth  = FALSE
        ),
        class    = "display nowrap compact",
        rownames = FALSE
      )
    })

    output$hist_plot <- shiny::renderPlot({
      shiny::req(input$num_col, input$num_bins)
      plot_numeric_histogram(df(), input$num_col, input$num_bins)
    }, bg = "transparent")

    output$bar_plot <- shiny::renderPlot({
      shiny::req(input$cat_col)
      plot_categorical_bar(df(), input$cat_col)
    }, bg = "transparent")
  })
}
