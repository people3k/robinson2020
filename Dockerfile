# get the base image, the rocker/verse has R, RStudio and pandoc
FROM rocker/geospatial:3.6.3

# required
MAINTAINER Kyle Bocinsky <bocinsky@gmail.com>

COPY . /robinson2020

# go into the repo directory
RUN . /etc/environment \

# build this compendium package
&& R -e "devtools::install('/robinson2020', dependencies = TRUE, quick = TRUE)" \

# render the manuscript into a pdf
&& R -e "rmarkdown::render('/robinson2020/analysis/robinson2020.Rmd')"
