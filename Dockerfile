# get the rocker/binder image
FROM rocker/geospatial:3.6.2
MAINTAINER Kyle Bocinsky <bocinsky@gmail.com>
USER root

COPY . '/robinson2020'

# install the repo
RUN R -e "devtools::install('/robinson2020', dependencies = TRUE, quick = TRUE)"

# Render the document
RUN R -e "rmarkdown::render('/robinson2020/analysis/robinson2020.Rmd')"
