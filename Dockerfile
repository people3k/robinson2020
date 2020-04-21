# get the rocker/binder image
FROM rocker/binder:3.6.2

## Declares build arguments
ARG NB_USER
ARG NB_UID

## Copies your repo files into the Docker Container
USER root

COPY . ${HOME}

RUN chown -R ${NB_USER} ${HOME}

## Become normal user again
USER ${NB_USER}

# install the repo
RUN R -e "devtools::install('${HOME}', dependencies = TRUE, quick = TRUE, upgrade = 'never')"

# Render the document
USER root
RUN R -e "rmarkdown::render('${HOME}/analysis/robinson2020.Rmd')"
USER ${NB_USER}
