library(shiny)
library(shinydashboard)

dashboardPage(

  dashboardHeader(
    title = tags$div(
      tags$img(src = "PUT_logo.png", height = "40px", width = "40px", style = "margin-right:10px;"),
      "EDA Dashboard"
    ),
    titleWidth = 230  # Optional: adjust based on logo+text width
  ),
  
    
  dashboardSidebar(
    sidebarMenu(
      menuItem(HTML("&nbsp;README"), tabName = "readme", icon = icon("book")),
      menuItem(HTML("&nbsp;Overview & Distribution"), tabName = "overview", icon = icon("chart-bar")),
      menuItem(HTML("&nbsp;Numerical Relationship"), tabName = "num_relation", icon = icon("project-diagram")),
      menuItem(HTML("&nbsp;Mixed-Type Relationship"), tabName = "mix_relation", icon = icon("layer-group"))
    )
  ),
  
  dashboardBody(
    tabItems(
      tabItem(tabName = "readme",
              h2("README"),
              p("This dashboard allows interactive exploration of a dataset...")
      ),
      tabItem(tabName = "overview",
              h2("Overview & General Distribution"),
              # Add histograms, bar charts, boxplots here
      ),
      tabItem(tabName = "num_relation",
              h2("Numerical Columns Relationship Analysis"),
              # Scatter plots, correlation heatmaps, parallel coordinate plots
      ),
      tabItem(tabName = "mix_relation",
              h2("Mixed-Type Relationship Analysis"),
              # Grouped bar charts, boxplots by category, violin plots, etc.
      )
    )
  )
)