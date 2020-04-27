FROM rocker/geospatial:3.6.3

LABEL maintainer="bocinsky@gmail.com"

ENV NB_USER rstudio
ENV NB_UID 1000
ENV VENV_DIR /srv/venv

# Set ENV for all programs...
ENV PATH ${VENV_DIR}/bin:$PATH
# And set ENV for R! It doesn't read from the environment...
RUN echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron
RUN echo "export PATH=${PATH}" >> ${HOME}/.profile

# The `rsession` binary that is called by nbrsessionproxy to start R doesn't seem to start
# without this being explicitly set
ENV LD_LIBRARY_PATH /usr/local/lib/R/lib

ENV HOME /home/${NB_USER}
WORKDIR ${HOME}

RUN apt-get update && \
    apt-get -y install python3-venv python3-dev && \
    apt-get purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a venv dir owned by unprivileged user & set up notebook in it
# This allows non-root to install python libraries if required
RUN mkdir -p ${VENV_DIR} && chown -R ${NB_USER} ${VENV_DIR}

USER ${NB_USER}
RUN python3 -m venv ${VENV_DIR} && \
    # Explicitly install a new enough version of pip
    pip3 install pip==9.0.1 && \
    pip3 install --no-cache-dir \
         jupyter-rsession-proxy

RUN R --quiet -e "devtools::install_github('IRkernel/IRkernel')" && \
    R --quiet -e "IRkernel::installspec(prefix='${VENV_DIR}')"


## Declares build arguments
ARG NB_USER
ARG NB_UID

## Copies your repo files into the Docker Container
USER root

COPY . ${HOME}

RUN chown -R ${NB_USER} ${HOME}

# Upgrade tinytex
RUN r -e "Sys.setenv('CTAN_REPO' = paste0('https://www.texlive.info/tlnet-archive/2020/04/23/tlnet')); tinytex::install_tinytex()"

# install the repo
RUN r -e "devtools::install('${HOME}', dependencies = TRUE, quick = TRUE, upgrade = 'never')"

# Render the document
#RUN r -e "rmarkdown::render('${HOME}/analysis/robinson2020.Rmd', params = list(cache = FALSE))"

## Become normal user again
USER ${NB_USER}
