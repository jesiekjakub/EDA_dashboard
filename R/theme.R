# bslib theme + matching plotly/ggplot helpers. Keeping these in one file
# so that "change the brand teal" is a single edit instead of grep-and-replace
# across every plot builder.

#' Top-level bslib theme.
#'
#' Darkly preset overridden with the brand teal/blue accents and an Inter
#' typography stack. Pinned to Bootstrap 5 because value_box() and the
#' full_screen card affordance both require BS5.
app_theme <- function() {
  bslib::bs_theme(
    version = 5,
    preset = "darkly",
    primary = "#18BC9C",
    secondary = "#3498DB",
    success = "#18BC9C",
    info = "#3498DB",
    warning = "#F39C12",
    danger = "#E74C3C",
    base_font = bslib::font_google("Inter"),
    heading_font = bslib::font_google("Inter"),
    "card-bg" = "#222831",
    "body-bg" = "#1a1d23",
    "border-color" = "rgba(255,255,255,0.08)"
  )
}

# Shared axis styling — muted grid lines and a tick font matching the body.
# Pulled out as a list so it composes with per-plot overrides via modifyList().
PLOTLY_AXIS <- list(
  color = "#cfd2d6",
  gridcolor = "rgba(255,255,255,0.06)",
  zerolinecolor = "rgba(255,255,255,0.12)",
  tickfont = list(family = "Inter, sans-serif", size = 11)
)

#' Build the layout arglist used by every plotly figure in the app.
#'
#' Transparent backgrounds let the dark card show through; explicit axis
#' overrides land in `xaxis_extra` / `yaxis_extra` so the caller doesn't
#' collide with the default axis style.
plotly_dark_layout <- function(xaxis_title = NULL,
                               yaxis_title = NULL,
                               xaxis_extra = list(),
                               yaxis_extra = list(),
                               ...) {
  xaxis <- utils::modifyList(PLOTLY_AXIS, c(
    if (!is.null(xaxis_title)) list(title = xaxis_title) else list(),
    xaxis_extra
  ))
  yaxis <- utils::modifyList(PLOTLY_AXIS, c(
    if (!is.null(yaxis_title)) list(title = yaxis_title) else list(),
    yaxis_extra
  ))

  list(
    paper_bgcolor = "rgba(0,0,0,0)",
    plot_bgcolor  = "rgba(0,0,0,0)",
    font          = list(family = "Inter, sans-serif", color = "#cfd2d6"),
    xaxis         = xaxis,
    yaxis         = yaxis,
    margin        = list(l = 60, r = 20, t = 40, b = 60),
    legend        = list(font = list(color = "#cfd2d6")),
    hoverlabel    = list(bgcolor = "#15181d", font = list(color = "#cfd2d6")),
    ...
  )
}

#' Sugar over `plotly::layout(p, ...)` that splats `plotly_dark_layout()`.
apply_dark_layout <- function(p, ...) {
  do.call(plotly::layout, c(list(p = p), plotly_dark_layout(...)))
}

#' ggplot theme matching the dark cards. Transparent backgrounds because
#' `renderPlot(..., bg = "transparent")` is used at the call site — the
#' card's CSS bg becomes the plot's bg.
#'
#' Grid color uses 8-char hex (#RRGGBBAA) instead of CSS rgba() — R's
#' base color parser doesn't accept rgba strings, only named colors and
#' hex. Plotly is fine with rgba because the strings flow to JS untouched.
dark_theme_minimal <- function() {
  ggplot2::theme_minimal(base_family = "Inter") +
    ggplot2::theme(
      plot.background  = ggplot2::element_rect(fill = "transparent", color = NA),
      panel.background = ggplot2::element_rect(fill = "transparent", color = NA),
      text             = ggplot2::element_text(color = "#cfd2d6"),
      axis.text        = ggplot2::element_text(color = "#cfd2d6"),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(color = "#FFFFFF10"),
      plot.margin      = ggplot2::margin(8, 14, 8, 14)
    )
}

#' Wire ggplot to bslib at startup so CSS variables (fonts, fg/bg) flow
#' through to renderPlot() outputs without needing per-plot wiring.
enable_themed_ggplots <- function() {
  thematic::thematic_shiny(font = "auto")
}
