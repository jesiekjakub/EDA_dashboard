# Numerical-relationships tab. The per-column range sliders are rendered
# dynamically because their min/max depend on the dataset that's only
# available once the CSV has loaded. filtered_df() composes the sliders
# into a single reactive that every plot on the tab reads from — pinching
# the row count once instead of re-filtering in every renderer.

numerical_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    bslib::layout_columns(
      col_widths = c(8, 4),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header("Correlation heatmap"),
        bslib::card_body(plotly::plotlyOutput(ns("correlation_heatmap"), height = "520px"))
      ),
      bslib::card(
        bslib::card_header("Range filters"),
        bslib::card_body(
          shiny::tags$p(
            "Sliders below filter the dataset feeding every plot on this tab.",
            class = "text-muted small mb-3"
          ),
          shiny::uiOutput(ns("dynamic_sliders"))
        )
      )
    ),
    bslib::layout_columns(
      col_widths = c(6, 6),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header("Scatter — colored by grade"),
        bslib::card_body(
          bslib::layout_columns(
            col_widths = c(6, 6),
            shiny::selectInput(ns("scatter_x"), "X attribute",
                               choices  = NUMERICAL_COLS,
                               selected = "study_hours_per_day"),
            shiny::selectInput(ns("scatter_y"), "Y attribute",
                               choices  = NUMERICAL_COLS,
                               selected = "exam_score")
          ),
          plotly::plotlyOutput(ns("scatter_plot"), height = "400px")
        )
      ),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header("2D density"),
        bslib::card_body(
          shiny::tags$p(
            "Uses the X / Y attributes selected on the scatter card.",
            class = "text-muted small mb-2"
          ),
          plotly::plotlyOutput(ns("density_plot"), height = "460px")
        )
      )
    ),
    bslib::layout_columns(
      col_widths = c(6, 6),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header("One-vs-all correlations"),
        bslib::card_body(
          shiny::selectInput(ns("one_vs_all"), "Target attribute",
                             choices  = NUMERICAL_COLS,
                             selected = "exam_score"),
          plotly::plotlyOutput(ns("one_vs_all_plot"), height = "440px")
        )
      ),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header("Top correlated pairs"),
        bslib::card_body(
          shiny::numericInput(ns("top_n_pairs"), "Number of pairs",
                              value = 8, min = 3, max = 15, step = 1),
          plotly::plotlyOutput(ns("top_pairs_plot"), height = "440px")
        )
      )
    )
  )
}

numerical_server <- function(id, df) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$dynamic_sliders <- shiny::renderUI({
      d <- df()
      sliders <- lapply(NUMERICAL_COLS, function(col) {
        vals <- d[[col]]
        # Floor/ceil to one decimal so the slider snaps to a clean range
        # even when the column itself is float-precision noisy.
        lo <- floor(min(vals,  na.rm = TRUE) * 10) / 10
        hi <- ceiling(max(vals, na.rm = TRUE) * 10) / 10
        shiny::sliderInput(
          inputId = ns(paste0(col, "_range")),
          label   = col,
          min     = lo,
          max     = hi,
          value   = c(lo, hi),
          step    = 0.1
        )
      })
      do.call(shiny::tagList, sliders)
    })

    filtered_df <- shiny::reactive({
      d <- df()
      for (col in NUMERICAL_COLS) {
        r <- input[[paste0(col, "_range")]]
        if (!is.null(r)) {
          d <- d[!is.na(d[[col]]) & d[[col]] >= r[[1]] & d[[col]] <= r[[2]], , drop = FALSE]
        }
      }
      d
    })

    output$correlation_heatmap <- plotly::renderPlotly({
      d <- filtered_df()
      shiny::validate(shiny::need(nrow(d) > 1, "No rows match the current filters."))
      plot_correlation_heatmap(d, NUMERICAL_COLS)
    })

    output$scatter_plot <- plotly::renderPlotly({
      shiny::req(input$scatter_x, input$scatter_y)
      d <- filtered_df()
      shiny::validate(shiny::need(nrow(d) > 0, "No rows match the current filters."))
      plot_scatter(d, input$scatter_x, input$scatter_y, color_by = "grade")
    })

    output$density_plot <- plotly::renderPlotly({
      shiny::req(input$scatter_x, input$scatter_y)
      d <- filtered_df()
      shiny::validate(shiny::need(nrow(d) > 0, "No rows match the current filters."))
      plot_density_2d(d, input$scatter_x, input$scatter_y)
    })

    output$one_vs_all_plot <- plotly::renderPlotly({
      shiny::req(input$one_vs_all)
      d <- filtered_df()
      shiny::validate(shiny::need(nrow(d) > 1, "Need at least 2 rows to compute correlations."))
      plot_one_vs_all_correlation(d, input$one_vs_all, NUMERICAL_COLS)
    })

    output$top_pairs_plot <- plotly::renderPlotly({
      shiny::req(input$top_n_pairs)
      d <- filtered_df()
      shiny::validate(shiny::need(nrow(d) > 1, "Need at least 2 rows to compute correlations."))
      plot_top_pair_correlations(d, NUMERICAL_COLS, n = input$top_n_pairs)
    })
  })
}
