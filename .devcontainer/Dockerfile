FROM mcr.microsoft.com/devcontainers/python:0-3.11

RUN apt-get -y update --no-install-recommends \
    && apt-get upgrade -y \
    && apt-get -y install --no-install-recommends \
    apt-utils \
    git \
    curl \
    zsh \
    vim \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && apt-get autoremove -y \
    && apt-get clean -y