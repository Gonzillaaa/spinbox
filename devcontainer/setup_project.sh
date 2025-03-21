#!/bin/bash

# install a new version of python with pyenv
pyenv install 3.11
pyenv global 3.11

#initialise poetry and install dependencies
poetry init -q
poetry shell
poetry add python-dotenv wheel


