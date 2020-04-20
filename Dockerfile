# get the rocker/binder image
FROM rocker/binder:3.6.2

## Declares build arguments
ARG NB_USER
ARG NB_UID

## Copies your repo files into the Docker Container
USER root
COPY . ${HOME}
## Enable this to copy files from the binder subdirectory
## to the home, overriding any existing files.
## Useful to create a setup on binder that is different from a
## clone of your repository
## COPY binder ${HOME}
RUN chown -R ${NB_USER} ${HOME}

## Become normal user again
USER ${NB_USER}

# install the repo
RUN R -e "devtools::install('${HOME}', dependencies = TRUE, quick = TRUE, upgrade = 'never')"

# Render the document
#RUN R -e "rmarkdown::render('${HOME}/analysis/robinson2020.Rmd')"
