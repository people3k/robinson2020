# get the rocker/binder image
FROM rocker/geospatial:3.6.3
LABEL maintainer='Kyle Bocinsky'
USER root
COPY . ${HOME}
RUN chown -R ${NB_USER} ${HOME}
USER ${NB_USER}

# install the repo
RUN R -e "devtools::install('${HOME}', dependencies = TRUE, quick = TRUE, upgrade = 'never')"

# Render the document
RUN R -e "rmarkdown::render('${HOME}/analysis/robinson2020.Rmd')"
