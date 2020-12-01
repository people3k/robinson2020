FROM people3k/robinson2020:1.0.1
LABEL maintainer="bocinsky@gmail.com"

## Declares build arguments
ARG NB_USER
ARG NB_UID

## Copies your repo files into the Docker Container
USER root

RUN chown -R ${NB_USER} ${HOME}

## Become normal user again
USER ${NB_USER}
