library(shiny)
library(shinydashboard)
library(readr)
library(dplyr)
library(DT)     
library(ggplot2)


function(input, output, session) {
  # Set which columns are numerical and which are categorical
  numerical_columns = c("age","study_hours_per_day","social_media_hours","netflix_hours","attendance_percentage","sleep_hours","exercise_frequency","mental_health_rating","exam_score","grade")
  categorical_columns = c("gender","part_time_job","diet_quality","parental_education_level","internet_quality","extracurricular_participation")
  
  
  # Load the whole dataset and create the new derived attribute "grade"
  main_df = read_csv("data/student_habits_performance.csv", show_col_types = FALSE) %>%
    mutate(
      grade = case_when(
        exam_score <= 50.0                 ~ 2.0,
        exam_score > 50 & exam_score <= 60 ~ 3.0,
        exam_score > 60 & exam_score <= 70 ~ 3.5,
        exam_score > 70 & exam_score <= 80 ~ 4.0,
        exam_score > 80 & exam_score <= 90 ~ 4.5,
        exam_score > 90                    ~ 5.0,
        TRUE ~ NA_real_
      )
    ) %>%
    select(-student_id)

  
  
### OVERVIEW ###################################################################   
  # Create datatable
  output$overview_student_table = renderDT({
    datatable(main_df,
              options = list(
                scrollX = TRUE,
                scrollY = "300px",
                pageLength = 10,
                filter = "top"
              ),
              class = "display nowrap")
  })
  
  # Create histogram
  output$overview_hist_plot <- renderPlot({
    req(input$overview_num_col) # one of the values must be chosen before displaying the chart (no errors displayed)
    ggplot(main_df, aes_string(x = input$overview_num_col)) +
      geom_histogram(bins = input$overview_num_bins, fill = "#0073C2FF", color = "white") +
      labs(x = input$overview_num_col, y = "Count") +
      theme_minimal()
  })
  
  # Create bar chart
  output$overview_bar_plot <- renderPlot({
    req(input$overview_cat_col) # one of the values must be chosen before displaying the chart (no errors displayed)
    ggplot(main_df, aes_string(x = input$overview_cat_col)) +
      geom_bar(fill = "#EFC000FF") +
      labs(x = input$overview_cat_col, y = "Count") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
### OVERVIEW ###################################################################  
  
  
}
