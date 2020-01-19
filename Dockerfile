## Use a tag instead of "latest" for reproducibility
FROM rocker/geospatial:3.6.2

# required
MAINTAINER Kyle Bocinsky <bocinsky@gmail.com>

## Declares build arguments
##ARG NB_USER
##ARG NB_UID

## Copies your repo files into the Docker Container
USER root
##COPY . /<REPO>
COPY . ${HOME}
## Enable this to copy files from the binder subdirectory
## to the home, overriding any existing files.
## Useful to create a setup on binder that is different from a
## clone of your repository
## COPY binder ${HOME}
##RUN chown -R ${NB_USER} ${HOME}
##RUN chown -R ${NB_USER} /<REPO>

## Become normal user again
##USER ${NB_USER}

# go into the repo directory
RUN . /etc/environment \
  # build this compendium package
  && R -e "devtools::install('${HOME}', dep=TRUE)" \
  # render the manuscript into a docx, you'll need to edit this if you've
  # customised the location and name of your main Rmd file
  && R -e "rmarkdown::render('${HOME}/analysis/paper/paper.Rmd')"
