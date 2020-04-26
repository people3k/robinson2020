FROM bocinsky/robinson2020

## Declares build arguments
ARG NB_USER
ARG NB_UID

## Copies your repo files into the Docker Container
USER root

RUN chown -R ${NB_USER} ${HOME}

## Become normal user again
USER ${NB_USER}
