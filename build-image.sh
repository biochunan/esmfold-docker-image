#!/bin/zsh 

WD=$(pwd)

# Build the image
docker build -t chunan/esmfold:base .
