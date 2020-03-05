# get the base image, the rocker/verse has R, RStudio and pandoc  
FROM rocker/geospatial:3.6.2

# required
MAINTAINER Kyle Bocinsky <bocinsky@gmail.com>

COPY . /robinson2020

# go into the repo directory
RUN . /etc/environment \

  # build this compendium package
  && R -e "devtools::install('/robinson2020', dependencies = c('Depends', 'Imports'))" \

 # render the manuscript into a docx, you'll need to edit this if you've
 # customised the location and name of your main Rmd file
  && R -e "rmarkdown::render('/robinson2020/analysis/paper/paper.Rmd')"
