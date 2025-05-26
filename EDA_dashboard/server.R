library(shiny)
library(shinydashboard)
library(readr)
library(dplyr)
library(DT)     
library(ggplot2)


function(input, output, session) {
  colors_palette = colorRampPalette(c("#3498DB", "#18BC9C", "#F39C12", "#E74C3C", "#8E44AD", "#2C3E50"))
  
  # Set which columns are numerical and which are categorical
  numerical_columns = c("age","study_hours_per_day","social_media_hours","netflix_hours","attendance_percentage","sleep_hours","exercise_frequency","mental_health_rating","exam_score","grade")
  categorical_columns = c("gender","part_time_job","diet_quality","parental_education_level","internet_quality","extracurricular_participation")
  
  
  # Load the whole dataset, create the new derived attribute "grade" and drop id column
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
  
  # Create histogram for numerical attributes
  output$overview_hist_plot = renderPlot({
    req(input$overview_num_col)
    ggplot(main_df, aes_string(x = input$overview_num_col)) +
      geom_histogram(bins = input$overview_num_bins, fill = colors_palette(1), color = "white") +
      labs(x = input$overview_num_col, y = "Count") +
      theme_minimal()
  })
  
  # Create bar chart for categorical attributes
  output$overview_bar_plot = renderPlot({
    req(input$overview_cat_col)
    categories = unique(main_df[[input$overview_cat_col]])
    n_categories = length(categories)
    fill_colors = setNames(colors_palette(n_categories), categories)
    ggplot(main_df, aes_string(x = input$overview_cat_col, fill = input$overview_cat_col)) +
      geom_bar() +
      scale_fill_manual(values = fill_colors) +
      labs(x = input$overview_cat_col, y = "Count") +
      theme_minimal() 
  })
  
### OVERVIEW ###################################################################  
  

### NUMERICAL RELATION #########################################################
  
  # Create dynamic sliders 
  output$num_relation_dynamic_sliders = renderUI({
    slider_ui = lapply(numerical_columns, function(col) {
      min_val = min(main_df[[col]], na.rm = TRUE)
      max_val = max(main_df[[col]], na.rm = TRUE)
      sliderInput(
        inputId = paste0(col, "_range"),
        label = paste("Filter:", col),
        min = min_val, max = max_val,
        value = c(min_val, max_val),
        step = 0.1
      )
    })
    do.call(tagList, slider_ui)
  }) 
  
  
  # Filter dataset based on sliders
  filtered_df = reactive({
    df = main_df
    for (col in numerical_columns) {
      range_input = input[[paste0(col, "_range")]]
      if (!is.null(range_input)) {
        df = df[df[[col]] >= range_input[1] & df[[col]] <= range_input[2], ]
      }
    }
    df
  })
  
  
  # Heatmap Plot
  output$num_relation_correlation_heatmap = renderPlotly({
    df = filtered_df()
    cor_matrix = cor(df[numerical_columns], use = "complete.obs")
    plot_ly(
      x = colnames(cor_matrix),
      y = colnames(cor_matrix),
      z = cor_matrix,
      type = "heatmap",
      colorscale = "RdBu"
      )
  })
  
  
  # Scatterplot
  output$num_relation_scatter_plot = renderPlotly({
    req(input$num_relation_scatter_x, input$num_relation_scatter_y)
    df = filtered_df() 
    plot_ly(
      data = df,
      x = ~get(input$num_relation_scatter_x),
      y = ~get(input$num_relation_scatter_y),
      color = ~factor(grade),
      colors = c("#3498DB", "#18BC9C", "#F39C12", "#E74C3C", "#8E44AD", "#2C3E50"),
      type = 'scatter',
      mode = 'markers',
      marker = list(size = 8, opacity = 0.6)
    ) %>%
      layout(
        xaxis = list(title = input$num_relation_scatter_x),
        yaxis = list(title = input$num_relation_scatter_y),
        legend = list(title = list(text = "Grade"))
      )
  })
  
  
  # Density plot
  output$num_relation_density_plot = renderPlotly({
    req(input$num_relation_scatter_x, input$num_relation_scatter_y)
    df = filtered_df()
    
    plot_ly(df, 
            x = ~get(input$num_relation_scatter_x), 
            y = ~get(input$num_relation_scatter_y), 
            type = "histogram2dcontour",
            colorscale = "RdBu",
            contours = list(coloring = "heatmap")) %>%
      layout(
        title = "2D Density Plot",
        xaxis = list(title = input$num_relation_scatter_x),
        yaxis = list(title = input$num_relation_scatter_y)
      )
  })
  
  # One-vs-All Correlation Plot
  output$num_relation_one_vs_all_plot = renderPlotly({
    req(input$num_relation_one_vs_all)
    df = filtered_df()
    target = input$num_relation_one_vs_all
    cor_vals = sapply(numerical_columns, function(col) {
      if (col == target) return(NA)
      cor(df[[target]], df[[col]], use = "complete.obs")
    })
    cor_df = data.frame(
      Attribute = numerical_columns,
      Correlation = cor_vals,
      stringsAsFactors = FALSE
    )
    cor_df = cor_df[!is.na(cor_df$Correlation), ]
    cor_df = cor_df[order(abs(cor_df$Correlation)), ]  # Sort by absolute value of correlation descending
    
    plot_ly(
      data = cor_df,
      x = ~reorder(Attribute, Correlation),  # x reordered by decreasing correlation
      y = ~Correlation,
      type = 'bar',
      marker = list(color = "#3498DB")
    ) %>%
      layout(
        yaxis = list(title = paste("Correlation with", target)),
        xaxis = list(title = "Other Attributes"),
        title = "One-vs-All Correlation"
      )
  })
  
### NUMERICAL RELATION #########################################################
  
### CATEGORICAL RELATION #######################################################

  # Create Heatmap
  output$mix_relation_heatmap_plot = renderPlotly({
    req(input$mix_relation_heat_x, input$mix_relation_heat_y)
    req(input$mix_relation_heat_x != input$mix_relation_heat_y)
    df = main_df
    x_col = input$mix_relation_heat_x
    y_col = input$mix_relation_heat_y
    
    # Group by the selected categorical variables
    grouped = df %>%
      group_by(.data[[x_col]], .data[[y_col]]) %>%
      summarise(Count = n(), .groups = "drop")
    
    # Rename to generic names for plotly to work with
    grouped = grouped %>%
      rename(X = !!x_col, Y = !!y_col)
    
    plot_ly(
      data = grouped,
      x = ~X,
      y = ~Y,
      z = ~Count,
      type = "heatmap",
      colors = "RdBu"
    ) %>%
      layout(
        title = "Heatmap of Counts",
        xaxis = list(title = x_col),
        yaxis = list(title = y_col)
      )
  })
  
  
  
  # Create Boxplots
  output$mix_relation_boxplot_plot = renderPlotly({
    req(input$mix_relation_box_x, input$mix_relation_box_y)
    df = filtered_df()
    
    plot_ly(
      data = df,
      x = ~.data[[input$mix_relation_box_x]],
      y = ~.data[[input$mix_relation_box_y]],
      type = "violin",
      color = ~.data[[input$mix_relation_box_x]],
      colors = c("#3498DB", "#18BC9C", "#F39C12", "#E74C3C", "#8E44AD"),
      box = list(visible = FALSE),        
      meanline = list(visible = TRUE),     
      points = FALSE 
    ) %>%
      layout(
        title = "Boxplot Grouped by Category",
        yaxis = list(title = input$mix_relation_box_y),
        xaxis = list(title = input$mix_relation_box_x),
        showlegend = FALSE
      )
  })
  
  
### CATEGORICAL RELATION #######################################################      
}
