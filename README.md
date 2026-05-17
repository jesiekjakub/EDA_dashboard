# Student Habits & Performance — EDA Dashboard

Fully interactive R Shiny dashboard for exploratory data analysis on a student-habits / academic-performance dataset. Every chart is reactive: pick attributes from dropdowns, filter rows with linked range sliders, hover for formatted tooltips, brush-zoom the Plotly canvas, expand any card to full-screen — changes propagate to every plot on the open tab in real time. Three analytical lenses (univariate distributions, numerical relationships, mixed-type relationships) wired together in a dark, card-based UI built with **bslib** and **Plotly**.

[![R](https://img.shields.io/badge/R-4.4-276DC3?style=flat-square&logo=r&logoColor=white)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Shiny-1.8-75AADB?style=flat-square&logo=rstudioide&logoColor=white)](https://shiny.posit.co/)
[![bslib](https://img.shields.io/badge/bslib-0.6-7952B3?style=flat-square&logo=bootstrap&logoColor=white)](https://rstudio.github.io/bslib/)
[![Plotly](https://img.shields.io/badge/Plotly-4.10-3F4F75?style=flat-square&logo=plotly&logoColor=white)](https://plotly.com/r/)
[![Docker](https://img.shields.io/badge/Docker-24%2B-2496ED?style=flat-square&logo=docker&logoColor=white)](https://www.docker.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

---

## 📊 Dataset

Source: [Student Habits vs Academic Performance](https://www.kaggle.com/datasets/jayaantanaath/student-habits-vs-academic-performance) on Kaggle.

The CSV isn't committed. The Docker workflow downloads it automatically on first start via a one-shot `fetcher` service that calls the Kaggle API with credentials from `.env` and then deletes its own bootstrap script from the working tree. See [`data/README.md`](data/README.md) for the full schema (10 numerical and 6 categorical attributes; `exam_score` is the headline target, the dashboard derives a 6-point `grade` column from it on load).

## 🧠 Features

### Overview & distribution
- Four KPI value boxes: student count, mean exam score, mean study hours per day, mean sleep hours.
- Searchable, sortable, paginated data table (DataTables).
- Per-column histogram for any numerical attribute, with an adjustable bin count.
- Per-column bar chart for any categorical attribute.

### Numerical relationships
- Pearson correlation heatmap across all numeric attributes, pinned to ±1 so the divergent palette anchors on zero.
- One range slider per numeric column. The sliders compose into a single filter that feeds every plot on the tab.
- Scatter plot of any two numeric attributes, colored by the derived `grade`.
- 2D kernel-density contour plot of the same pair.
- One-vs-all correlation bar chart ranking every other column against a chosen target, sorted by `|r|` descending.

### Mixed-type relationships
- Joint-count heatmap of any two categorical attributes (sequential Viridis colorscale — counts are non-negative).
- Violin plot of any numeric attribute split by a categorical one, with embedded box and mean line.

## 🎛️ Interactivity

The dashboard is built around live reactivity — there are no rendered static screenshots, every view recomputes from current input state.

- **Linked range sliders.** Each numeric column gets its own slider on the Numerical relations tab. Adjust any one and the correlation heatmap, scatter, 2D density, one-vs-all bar chart, and top-pair ranking all recompute against the filtered subset. Filters compose, so narrowing two columns intersects their constraints.
- **Dropdown-driven axes.** X / Y attributes for the scatter, density, mixed-type heatmap, and violin plots are picked from the column list at runtime. The 2D density automatically follows the scatter's X / Y choice — pick once, both views update.
- **Plotly tooltips.** Hover over any point, bar, or heatmap cell to see formatted values: `r = -0.231`, `n = 184`, full attribute names on both axes.
- **Plotly toolbar.** Built into every chart — box-zoom, pan, autoscale, download as PNG, reset. No extra wiring on the R side.
- **Full-screen toggle.** Every plot card has a corner button that expands the chart to a full-viewport overlay; click again to dock back.
- **Searchable data table.** The Overview table supports column-by-column sorting, full-text search across all rows, and pagination via the DataTables JS library.
- **Friendly empty states.** When filters narrow the dataset to too few rows, the affected charts swap their canvas for a concise "no rows match the current filters" card instead of erroring out.
- **Configurable top-N.** The Top correlated pairs chart's depth (3–15 pairs) is user-adjustable on the fly.

## 🛠️ Tech Stack

### Backend
- **R 4.4** — runtime
- **Shiny 1.8+** — reactive UI framework with first-class module support (`moduleServer`)
- **bslib 0.6+** — Bootstrap 5 theming, `card()` / `value_box()` primitives, full-screen plot affordance
- **dplyr** + **readr** — data wrangling and CSV ingest

### Visualization
- **Plotly** — interactive heatmaps, scatter, 2D density contours, violins
- **ggplot2** + **thematic** — themed static plots (distributions on the Overview tab)
- **DT** — interactive data table

### Infrastructure
- **Docker** — multi-stage build on `rocker/r-ver:4.4.0`; runtime image runs as a non-root user
- **Docker Compose** — two services: a one-shot `fetcher` (python:3.12-slim + `kaggle`) that downloads the dataset on first run and self-deletes its bootstrap script, plus the long-running `eda` Shiny container

## 📁 Project Structure

```text
EDA_dashboard/
├── app.R                     # Shiny entry point
├── R/
│   ├── globals.R             # column metadata, brand palette
│   ├── theme.R               # bslib theme + plotly/ggplot helpers
│   ├── data.R                # load + schema validation + grade derivation
│   ├── plots.R               # pure plot builders
│   ├── mod_overview.R        # Overview & distribution tab
│   ├── mod_numerical.R       # Numerical relationships tab
│   ├── mod_mixed.R           # Mixed-type relationships tab
│   └── mod_about.R           # About / methodology tab
├── www/
│   ├── styles.css            # polish on top of the Darkly preset
│   └── PUT_logo.png          # header glyph
├── data/
│   └── README.md             # schema + Kaggle source
├── bootstrap_data.py         # one-shot Kaggle fetcher (self-deletes after first success)
├── DESCRIPTION               # rsconnect-style dependency manifest
├── install.R                 # one-shot installer for local R
├── Dockerfile                # multi-stage rocker/r-ver build
├── docker-compose.yml        # fetcher + eda services
├── .env.example
├── .gitignore
├── .dockerignore
├── LICENSE
└── README.md
```

## ⚙️ Environment Variables

The Compose tunables live in `.env` (copy from `.env.example`). Kaggle credentials are NOT in `.env` — the fetcher bind-mounts `~/.kaggle/` from the host instead, so whichever credential file you already have (`access_token` or legacy `kaggle.json`) works without further setup.

| Variable | Default | Purpose |
|---|---|---|
| `SHINY_PORT` | `3838` | Host port the dashboard is exposed on. |
| `R_MAX_VSIZE` | `4Gb` | Per-worker R heap cap. Bump if Plotly serialization OOMs on a large filtered subset. |

## 🚀 Setup

### Prerequisites
- **Docker 24+** (recommended path), or **R 4.4+** for non-containerized runs
- Kaggle credentials on the host at `~/.kaggle/` (one of):
  - `~/.kaggle/access_token` — new OAuth token (`KGAT_...`), from [kaggle.com/settings](https://www.kaggle.com/settings) → Account → Create New Token
  - `~/.kaggle/kaggle.json` — legacy username + key JSON

  Either way, `chmod 600` on the credential file is recommended.

### Docker (recommended)
```bash
docker compose up --build
```

Then open `http://localhost:3838`.

On first start the `fetcher` service downloads the dataset to `./data/` and then deletes `bootstrap_data.py` from the working tree — the script is intentionally single-use. If you ever need it back, `git checkout bootstrap_data.py` restores it.

### Local (without Docker)

Drop `student_habits_performance.csv` into `data/` (manually from Kaggle, or run `pip install kagglehub && python bootstrap_data.py` once with `~/.kaggle/` credentials in place), then:

```bash
Rscript install.R
R -e "shiny::runApp('.', port = 3838)"
```

## 🏛️ Key Architecture Decisions

- **bslib over shinydashboard.** Bootstrap 5 cards, value boxes, and `page_navbar()` give modern primitives out of the box; `shinydashboard` has had no substantive UI work in years.
- **Shiny modules per tab.** Each tab is a namespaced module (`overview_*`, `numerical_*`, `mixed_*`, `about_*`). Adding a new tab is a new file under `R/` plus three lines in `app.R` — no churn elsewhere.
- **Pure plot builders.** `R/plots.R` exposes data-in/figure-out functions. Reactives in the modules pull `input$*` and call these builders. The same logic can back a static export or a snapshot test without rewiring.
- **Lazy dataset loading.** `load_dataset()` runs inside a `reactive()`, with `shiny::validate()` for both file existence and schema. A missing or malformed CSV surfaces as a friendly card per plot rather than a worker crash.
- **Single shared data reactive.** Built once in `app.R` and passed into each module — every tab observes the same dataset without re-reading the CSV.
- **Centralized theme.** `R/theme.R` defines the `bs_theme()` palette, a `plotly_dark_layout()` helper applied to every Plotly figure, and a matching `dark_theme_minimal()` for ggplot. Re-branding is a one-file edit.
- **Multi-stage Docker.** Builder stage resolves dependencies via `pak::local_install_deps()` against `DESCRIPTION`; runtime stage carries only the compiled R library and the app source. Smaller surface, faster cold starts.
- **One-shot fetcher in compose, not a long-lived sidecar.** A separate `python:3.12-slim` container runs `bootstrap_data.py` on first compose-up, then exits. The Shiny service blocks on `condition: service_completed_successfully` so it never starts without data. The bootstrap script deletes itself from the host working tree after a successful download — Python is not a permanent project dependency, it's a one-time setup tool.
- **Kaggle auth via host bind-mount, not env vars.** `~/.kaggle/` is mounted read-only into the fetcher. `kagglehub` auto-detects whichever credential file is present (new `access_token` or legacy `kaggle.json`), so no token plaintext lives in `.env` or compose output.

## 📝 License

[MIT](LICENSE)
