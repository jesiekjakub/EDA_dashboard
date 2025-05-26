library(shiny)
library(shinydashboard)
library(readr)
library(dplyr)
library(DT)

numerical_columns = c("age","study_hours_per_day","social_media_hours","netflix_hours","attendance_percentage","sleep_hours","exercise_frequency","mental_health_rating","exam_score","grade")
categorical_columns = c("gender","part_time_job","diet_quality","parental_education_level","internet_quality","extracurricular_participation")

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
              fluidRow(
                box(title = "Dataset Overview", width = 12, status = "primary", solidHeader = TRUE,
                    DTOutput("overview_student_table"))
              ),
              fluidRow(
                box(title = "Numerical Feature Distribution", width = 12, status = "info", solidHeader = TRUE,
                    selectInput("overview_num_col", "Choose Numerical Feature:", choices = numerical_columns),
                    sliderInput("overview_num_bins", "Number of bins:", min = 5, max = 50, value = 20),
                    plotOutput("overview_hist_plot"))
              ),
              fluidRow(
                box(title = "Categorical Feature Distribution", width = 12, status = "info", solidHeader = TRUE,
                    selectInput("overview_cat_col", "Choose Categorical Feature:", choices = categorical_columns),
                    plotOutput("overview_bar_plot"))
              )
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