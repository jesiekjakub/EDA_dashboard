# Entry point. Sources every file under R/ (order-independent — each
# file just defines top-level functions, no side effects), wires the
# tab modules into a bslib navbar, and shares a single dataset reactive
# across them.

library(shiny)
library(bslib)
library(dplyr)
library(readr)
library(DT)
library(plotly)
library(ggplot2)
library(thematic)
library(rlang)

lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source)

enable_themed_ggplots()

ui <- bslib::page_navbar(
  title = tags$div(
    tags$img(src = "PUT_logo.png"),
    tags$span("Student Habits — EDA", class = "brand-text")
  ),
  theme    = app_theme(),
  bg       = "#15181d",
  fillable = FALSE,
  header   = tags$head(
    tags$link(rel = "stylesheet", href = "styles.css"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1")
  ),

  bslib::nav_panel("Overview",              icon = icon("chart-column"), overview_ui("overview")),
  bslib::nav_panel("Numerical relations",   icon = icon("project-diagram"), numerical_ui("numerical")),
  bslib::nav_panel("Mixed-type relations",  icon = icon("layer-group"),  mixed_ui("mixed")),
  bslib::nav_spacer(),
  bslib::nav_panel("About",                 icon = icon("circle-info"),  about_ui("about"))
)

server <- function(input, output, session) {
  # Single shared dataset reactive. Each module receives this and pulls
  # df() inside its renderers, so a missing CSV manifests as a graceful
  # validate() card per plot instead of a worker crash.
  df <- shiny::reactive({
    load_dataset()
  })

  overview_server("overview", df)
  numerical_server("numerical", df)
  mixed_server("mixed", df)
}

shinyApp(ui, server)
