# Mixed-type relationships tab. Two cards: joint-count heatmap for two
# categoricals, and a violin plot of a numeric attribute split by a
# categorical one.

mixed_ui <- function(id) {
  ns <- shiny::NS(id)

  shiny::tagList(
    bslib::card(
      full_screen = TRUE,
      bslib::card_header("Categorical co-occurrence heatmap"),
      bslib::card_body(
        bslib::layout_columns(
          col_widths = c(6, 6),
          shiny::selectInput(ns("heat_x"), "X attribute",
                             choices  = CATEGORICAL_COLS,
                             selected = "diet_quality"),
          shiny::selectInput(ns("heat_y"), "Y attribute",
                             choices  = CATEGORICAL_COLS,
                             selected = "internet_quality")
        ),
        plotly::plotlyOutput(ns("heatmap_plot"), height = "460px")
      )
    ),
    bslib::card(
      full_screen = TRUE,
      bslib::card_header("Numeric distribution by category"),
      bslib::card_body(
        bslib::layout_columns(
          col_widths = c(6, 6),
          shiny::selectInput(ns("box_x"), "Categorical (X)",
                             choices  = CATEGORICAL_COLS,
                             selected = "diet_quality"),
          shiny::selectInput(ns("box_y"), "Numeric (Y)",
                             choices  = NUMERICAL_COLS,
                             selected = "exam_score")
        ),
        plotly::plotlyOutput(ns("boxplot_plot"), height = "460px")
      )
    )
  )
}

mixed_server <- function(id, df) {
  shiny::moduleServer(id, function(input, output, session) {

    output$heatmap_plot <- plotly::renderPlotly({
      shiny::req(input$heat_x, input$heat_y)
      shiny::validate(shiny::need(
        input$heat_x != input$heat_y,
        "Pick two different attributes to compare."
      ))
      plot_categorical_heatmap(df(), input$heat_x, input$heat_y)
    })

    output$boxplot_plot <- plotly::renderPlotly({
      shiny::req(input$box_x, input$box_y)
      plot_violin(df(), input$box_x, input$box_y)
    })
  })
}
