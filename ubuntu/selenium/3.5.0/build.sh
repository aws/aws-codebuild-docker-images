#!/usr/bin/env bash

# Build the docker image
docker build -t cpcp-selenium-testnode .

#get a docker login command from ecr
DOCKER_LOGIN_CMD=$(aws ecr get-login --no-include-email --region us-west-2)

# execute the login command
$DOCKER_LOGIN_CMD

# Tag the build
docker tag cpcp-selenium-testnode:latest 691137825721.dkr.ecr.us-west-2.amazonaws.com/cpcp-selenium-testnode:latest

# Push it
echo "Starting push"
docker push 691137825721.dkr.ecr.us-west-2.amazonaws.com/cpcp-selenium-testnode:latest
echo "Push finished"
