#!/usr/bin/env bash

CONTAINER_NAME=codebuild/nodejs-7.10.1

# Build the docker image
docker build -t $CONTAINER_NAME .

#get a docker login command from ecr
DOCKER_LOGIN_CMD=$(aws ecr get-login --no-include-email --region us-west-2)

# execute the login command
echo $DOCKER_LOGIN_CMD
$DOCKER_LOGIN_CMD

# Tag the build
docker tag $CONTAINER_NAME:latest 691137825721.dkr.ecr.us-west-2.amazonaws.com/$CONTAINER_NAME:latest

# Push it
echo "Starting push"
docker push 691137825721.dkr.ecr.us-west-2.amazonaws.com/$CONTAINER_NAME:latest
echo "Push finished"
