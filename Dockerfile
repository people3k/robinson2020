# get the rocker/binder image
FROM rocker/binder:3.6.2
# required
MAINTAINER Kyle Bocinsky <bocinsky@gmail.com>
LABEL maintainer='Kyle Bocinsky'
USER root
COPY . ${HOME}
RUN chown -R ${NB_USER} ${HOME}
USER ${NB_USER}

# go into the repo directory
RUN . /etc/environment \
&& R -e "devtools::install('${HOME}', dependencies = TRUE, quick = TRUE)" \
&& R -e "rmarkdown::render('${HOME}/analysis/robinson2020.Rmd')"
