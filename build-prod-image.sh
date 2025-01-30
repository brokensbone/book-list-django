#!/bin/bash

REPO="805091204988.dkr.ecr.eu-west-2.amazonaws.com/testing/books"
TAG=`date +%Y-%m-%d-%H-%M-%S`
docker build . --platform="linux/amd64" -t $REPO:$TAG -t $REPO:latest
docker push $REPO:$TAG