FROM rocker/binder:3.6.0
LABEL maintainer='Kyle Bocinsky'
USER root
COPY . ${HOME}
RUN chown -R ${NB_USER} ${HOME}
USER ${NB_USER}

# go into the repo directory
RUN . /etc/environment \

  # build this compendium package
  && R -e "options(repos = list(CRAN = 'http://mran.revolutionanalytics.com/snapshot/2020-01-19/'))" \

 # render the manuscript into a docx, you'll need to edit this if you've
 # customised the location and name of your main Rmd file
  && R -e "devtools::install_local('${HOME}', dependencies = c('Depends', 'Imports'))"

