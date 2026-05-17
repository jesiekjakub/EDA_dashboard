# Multi-stage build. The builder resolves and compiles R dependencies
# with pak (much faster than install.packages on a cold cache and pulls
# system deps automatically); the runtime stage carries only the compiled
# library + app source, runs as a non-root user, and exposes a healthcheck.

# syntax=docker/dockerfile:1.7

# -------- builder ----------------------------------------------------------
FROM rocker/r-ver:4.4.0 AS builder

# Headers needed at compile time for the SSL/HTTP/XML stack — pak still
# needs to link against these even though it fetches binary packages
# wherever possible.
RUN apt-get update && apt-get install -y --no-install-recommends \
      libcurl4-openssl-dev \
      libssl-dev \
      libxml2-dev \
      libfontconfig1-dev \
      libfreetype6-dev \
    && rm -rf /var/lib/apt/lists/*

# Install pak from its dedicated binary repo. The URL template is the
# canonical install snippet from r-lib/pak; substitutes the running R's
# OS and arch so we get prebuilt binaries.
RUN R -e "install.packages('pak', repos = sprintf('https://r-lib.github.io/p/pak/stable/%s/%s/%s', .Platform\$pkgType, R.Version()\$os, R.Version()\$arch))"

WORKDIR /build
COPY DESCRIPTION .

# `local_install_deps(".")` reads DESCRIPTION's Imports and installs them
# into the system library at /usr/local/lib/R/site-library, which we then
# copy whole into the runtime stage.
RUN R -e "pak::local_install_deps('.', ask = FALSE, dependencies = TRUE)"

# -------- runtime ----------------------------------------------------------
FROM rocker/r-ver:4.4.0

# Runtime shared libraries only (no -dev headers). curl is here for the
# HEALTHCHECK below.
RUN apt-get update && apt-get install -y --no-install-recommends \
      libcurl4 \
      libssl3 \
      libxml2 \
      libxt6 \
      libfontconfig1 \
      libfreetype6 \
      curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# Non-root user. Matches host uid 1000 by convention so a bind-mounted
# `data/` is owned by the same uid on both sides.
RUN useradd --create-home --shell /bin/bash --uid 1000 shiny
USER shiny
WORKDIR /home/shiny/app

COPY --chown=shiny:shiny app.R   ./
COPY --chown=shiny:shiny R/      ./R/
COPY --chown=shiny:shiny www/    ./www/

EXPOSE 3838

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS http://localhost:3838/ || exit 1

CMD ["R", "-e", "shiny::runApp('.', host = '0.0.0.0', port = 3838)"]
