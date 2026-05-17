# Plot builders. Pure functions: data frame + parameters in, figure out.
# No reactives, no Shiny inputs — modules pull input$* and call these
# explicitly, which keeps the builders testable in isolation and lets
# the same logic back a future export-to-PNG path or snapshot test.

#' Histogram of a single numeric column.
plot_numeric_histogram <- function(df, column, bins = 24) {
  ggplot2::ggplot(df, ggplot2::aes(x = .data[[column]])) +
    ggplot2::geom_histogram(
      bins      = bins,
      fill      = BRAND_PALETTE[1],
      color     = "#1a1d23",
      linewidth = 0.3
    ) +
    ggplot2::labs(x = column, y = "Count") +
    dark_theme_minimal()
}

#' Bar chart of a categorical column. Bars colored from the brand ramp;
#' legend suppressed since the x-axis already labels each bar.
plot_categorical_bar <- function(df, column) {
  categories  <- sort(unique(df[[column]]))
  fill_colors <- stats::setNames(make_palette(length(categories)), categories)

  ggplot2::ggplot(df, ggplot2::aes(x = .data[[column]], fill = .data[[column]])) +
    ggplot2::geom_bar() +
    ggplot2::scale_fill_manual(values = fill_colors, guide = "none") +
    ggplot2::labs(x = column, y = "Count") +
    dark_theme_minimal()
}

#' Pearson correlation matrix as an interactive heatmap.
#' zmin/zmax pinned to ±1 so the divergent palette anchors on zero
#' regardless of the actual correlation range in the filtered subset.
plot_correlation_heatmap <- function(df, cols) {
  cor_matrix <- stats::cor(df[, cols, drop = FALSE], use = "complete.obs")

  p <- plotly::plot_ly(
    x             = colnames(cor_matrix),
    y             = colnames(cor_matrix),
    z             = cor_matrix,
    type          = "heatmap",
    colorscale    = "RdBu",
    reversescale  = TRUE,
    zmin          = -1,
    zmax          = 1,
    hovertemplate = "%{x} ~ %{y}<br>r = %{z:.3f}<extra></extra>"
  )
  apply_dark_layout(p)
}

#' Scatter of two numeric attributes; optionally colored by a categorical.
plot_scatter <- function(df, x, y, color_by = NULL) {
  marker_base <- list(
    size    = 7,
    opacity = 0.65,
    line    = list(width = 0.4, color = "rgba(255,255,255,0.15)")
  )

  if (!is.null(color_by) && color_by %in% names(df)) {
    p <- plotly::plot_ly(
      x             = df[[x]],
      y             = df[[y]],
      color         = factor(df[[color_by]]),
      colors        = BRAND_PALETTE,
      type          = "scatter",
      mode          = "markers",
      marker        = marker_base,
      hovertemplate = paste0(x, ": %{x}<br>", y, ": %{y}<extra>%{fullData.name}</extra>")
    )
  } else {
    p <- plotly::plot_ly(
      x             = df[[x]],
      y             = df[[y]],
      type          = "scatter",
      mode          = "markers",
      marker        = c(marker_base, list(color = BRAND_PALETTE[1])),
      hovertemplate = paste0(x, ": %{x}<br>", y, ": %{y}<extra></extra>")
    )
  }

  apply_dark_layout(p, xaxis_title = x, yaxis_title = y)
}

#' 2D kernel-density contour. Reversed RdBu so high-density regions
#' read as warm — easier to scan than the default blue-on-blue.
plot_density_2d <- function(df, x, y) {
  p <- plotly::plot_ly(
    x             = df[[x]],
    y             = df[[y]],
    type          = "histogram2dcontour",
    colorscale    = "RdBu",
    reversescale  = TRUE,
    contours      = list(coloring = "heatmap"),
    hovertemplate = paste0(x, ": %{x}<br>", y, ": %{y}<br>count: %{z}<extra></extra>")
  )
  apply_dark_layout(p, xaxis_title = x, yaxis_title = y)
}

#' Ranked correlation of every other numeric column against `target`.
#' Sort key is |correlation|, descending — original code claimed
#' "decreasing" in a comment but sorted ascending by raw value.
plot_one_vs_all_correlation <- function(df, target, cols) {
  others <- setdiff(cols, target)
  cor_vals <- vapply(others, function(col) {
    suppressWarnings(stats::cor(df[[target]], df[[col]], use = "complete.obs"))
  }, numeric(1))

  ranking <- data.frame(
    attribute   = others,
    correlation = cor_vals,
    stringsAsFactors = FALSE
  )
  ranking <- ranking[!is.na(ranking$correlation), ]
  ranking <- ranking[order(-abs(ranking$correlation)), ]

  bar_colors <- ifelse(ranking$correlation >= 0,
                       BRAND_PALETTE[1],
                       BRAND_PALETTE[4])

  p <- plotly::plot_ly(
    x             = factor(ranking$attribute, levels = ranking$attribute),
    y             = ranking$correlation,
    type          = "bar",
    marker        = list(color = bar_colors),
    hovertemplate = "%{x}<br>r = %{y:.3f}<extra></extra>"
  )

  apply_dark_layout(
    p,
    xaxis_title = "Other attributes",
    yaxis_title = paste("Correlation with", target),
    # Pin the |r|-descending order; otherwise plotly silently re-sorts
    # the categorical x-axis alphabetically when the trace data comes in
    # as a factor.
    xaxis_extra = list(
      categoryorder = "array",
      categoryarray = as.character(ranking$attribute)
    ),
    yaxis_extra = list(range = c(-1, 1))
  )
}

#' Top-N strongest pairwise Pearson correlations across the numeric
#' columns, as a horizontal bar chart. Complements the one-vs-all view:
#' that one is target-conditional, this one ranks every unordered pair.
plot_top_pair_correlations <- function(df, cols, n = 8) {
  cor_matrix <- stats::cor(df[, cols, drop = FALSE], use = "complete.obs")

  # Upper triangle only — each unordered pair counted once, diagonal excluded.
  idx <- which(upper.tri(cor_matrix), arr.ind = TRUE)
  pairs <- data.frame(
    a = rownames(cor_matrix)[idx[, 1]],
    b = colnames(cor_matrix)[idx[, 2]],
    r = cor_matrix[idx],
    stringsAsFactors = FALSE
  )
  pairs <- pairs[!is.na(pairs$r), ]
  pairs <- pairs[order(-abs(pairs$r)), ]
  pairs <- utils::head(pairs, n)

  # Order ascending so the strongest bar lands on top of the y-axis.
  pairs <- pairs[order(abs(pairs$r)), ]
  pairs$label <- paste(pairs$a, "↔", pairs$b)

  bar_colors <- ifelse(pairs$r >= 0, BRAND_PALETTE[1], BRAND_PALETTE[4])

  p <- plotly::plot_ly(
    x             = pairs$r,
    y             = factor(pairs$label, levels = pairs$label),
    type          = "bar",
    orientation   = "h",
    marker        = list(color = bar_colors),
    hovertemplate = "%{y}<br>r = %{x:.3f}<extra></extra>"
  )

  apply_dark_layout(
    p,
    xaxis_title = "Pearson r",
    yaxis_title = "",
    xaxis_extra = list(range = c(-1, 1), zeroline = TRUE,
                       zerolinecolor = "rgba(255,255,255,0.2)",
                       zerolinewidth = 1)
  )
}

#' Co-occurrence heatmap of two categorical columns. Sequential
#' (Viridis) colorscale — counts are non-negative, no zero to diverge from.
plot_categorical_heatmap <- function(df, x, y) {
  counts <- df |>
    dplyr::group_by(.data[[x]], .data[[y]]) |>
    dplyr::summarise(n = dplyr::n(), .groups = "drop")

  x_levels <- sort(unique(counts[[x]]))
  y_levels <- sort(unique(counts[[y]]))

  # Pivot the long-form counts into a dense matrix so plotly's heatmap
  # gets axis-aligned rows/cols even for sparse combinations.
  mat <- matrix(
    0L,
    nrow     = length(y_levels),
    ncol     = length(x_levels),
    dimnames = list(y_levels, x_levels)
  )
  for (i in seq_len(nrow(counts))) {
    mat[counts[[y]][i], counts[[x]][i]] <- counts$n[i]
  }

  p <- plotly::plot_ly(
    x             = x_levels,
    y             = y_levels,
    z             = mat,
    type          = "heatmap",
    colorscale    = "Viridis",
    hovertemplate = paste0(x, ": %{x}<br>", y, ": %{y}<br>n = %{z}<extra></extra>")
  )
  apply_dark_layout(p, xaxis_title = x, yaxis_title = y)
}

#' Violin plot of a numeric column split by a categorical one.
plot_violin <- function(df, cat, num) {
  cat_levels <- sort(unique(df[[cat]]))
  colors     <- make_palette(length(cat_levels))

  p <- plotly::plot_ly(
    x             = df[[cat]],
    y             = df[[num]],
    color         = factor(df[[cat]], levels = cat_levels),
    colors        = colors,
    type          = "violin",
    box           = list(visible = TRUE, width = 0.18, line = list(color = "#cfd2d6")),
    meanline      = list(visible = TRUE, color = "#ffffff"),
    points        = "outliers",
    hovertemplate = paste0(num, ": %{y:.2f}<extra>%{x}</extra>")
  )

  apply_dark_layout(
    p,
    xaxis_title = cat,
    yaxis_title = num,
    showlegend  = FALSE
  )
}

