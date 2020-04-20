# get the rocker/binder image
FROM rocker/geospatial:devel
LABEL maintainer='Kyle Bocinsky'
USER root
COPY . /robinson2020

# install the repo
RUN R -e "devtools::install('/robinson2020', dependencies = TRUE, quick = TRUE, upgrade = 'never')"

# Render the document
#RUN R -e "rmarkdown::render('/robinson2020/analysis/robinson2020.Rmd')"
