FROM rocker/r-ver:4.0.3

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

ENV R_LIBS_SITE=/opt/globiom-downscaler-merger/r-lib

WORKDIR /opt/globiom-downscaler-merger

RUN mkdir -p /opt/globiom-downscaler-merger/r-lib && \
    Rscript -e 'install.packages(c("readr"), lib="/opt/globiom-downscaler-merger/r-lib", repos="https://packagemanager.posit.co/cran/2022-11-30")'

COPY merge_downscaling.R /opt/globiom-downscaler-merger/merge_downscaling.R

RUN Rscript --vanilla -e 'library(readr); cat("ok\n")'
