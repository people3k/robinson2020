# get the base image, the rocker/verse has R, RStudio and pandoc
FROM rocker/geospatial:3.6.1

# required
MAINTAINER Kyle Bocinsky <bocinsky@gmail.com>

COPY . /<REPO>

# go into the repo directory
RUN . /etc/environment \
  # build this compendium package
  && R -e "devtools::install('/<REPO>', dep=TRUE)" \
  # render the manuscript into a docx, you'll need to edit this if you've
  # customised the location and name of your main Rmd file
  && R -e "rmarkdown::render('/<REPO>/analysis/paper/paper.Rmd')"
