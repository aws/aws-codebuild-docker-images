#!/usr/bin/env bash

# Build the docker image
docker build -t codebuild/python-3.6.1 .

#get a docker login command from ecr
DOCKER_LOGIN_CMD=$(aws ecr get-login --no-include-email --region us-west-2)

# execute the login command
$DOCKER_LOGIN_CMD

# Tag the build
docker tag codebuild/python-3.6.1:latest 691137825721.dkr.ecr.us-west-2.amazonaws.com/codebuild/python-3.6.1:latest

# Push it
echo "Starting push"
docker push 691137825721.dkr.ecr.us-west-2.amazonaws.com/codebuild/python-3.6.1:latest
echo "Push finished"
