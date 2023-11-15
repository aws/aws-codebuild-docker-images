# AWS CodeBuild curated Docker images

This repository holds Dockerfiles of official AWS CodeBuild curated Docker images. Please refer to [the AWS CodeBuild User Guide](http://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref.html) for list of environments supported by AWS CodeBuild.

![Build Status](https://codebuild.us-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiSkJibVVQVEpvUms1cmw3YVlnU1hSdkpBQ0c5SFgyTkJXMFBFdEU2SWtySHREcUlUVlRhbW4zMEd3NlhsOWIzUWgvRkxhUWVSSTFPZGNNakNHRVNLalY0PSIsIml2UGFyYW1ldGVyU3BlYyI6IlV0QjBRZXRvS0F5dE5vbTciLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master)

The master branch will sometimes have changes that are still in the process of being released in AWS CodeBuild.  See the latest released versions of the Dockerfiles [here](https://github.com/aws/aws-codebuild-docker-images/releases)

### How to build Docker images

Steps to build Standard 8.0 image

* Run `git clone https://github.com/aws/aws-codebuild-docker-images.git` to download this repository to your local machine
* Run `cd aws-codebuild-docker-images/ubuntu/standard/8.0` to change the directory in your local workspace. This is the location of the Standard 8.0 Dockerfile with Ubuntu base.
* Run `docker build -t aws/codebuild/standard:8.0 .` to build Docker image locally

To poke around in the image interactively, build it and run:
`docker run -it --entrypoint sh aws/codebuild/standard:8.0 -c bash`

To let the Docker daemon start up in the container, build it and run:
`docker run -it --privileged aws/codebuild/standard:8.0 bash`

```
$ git clone https://github.com/aws/aws-codebuild-docker-images.git
$ cd aws-codebuild-docker-images
$ cd ubuntu/standard/8.0
$ docker build -t aws/codebuild/standard:8.0 .
$ docker run -it --entrypoint sh aws/codebuild/standard:8.0 -c bash
```

### Image maintenance

Some of the images in this repository are no longer actively maintained by AWS CodeBuild and may no longer build successfully.  These images will not receive any further updates.  They remain in this repository as a reference for the contents of these images that were previously released by CodeBuild.

The following images are actively maintained by AWS CodeBuild, and are listed in the CodeBuild console.

+ [standard 5.0](ubuntu/standard/5.0)
+ [standard 6.0](ubuntu/standard/6.0)
+ [standard 7.0](ubuntu/standard/7.0)
+ [standard 8.0](ubuntu/standard/8.0)
+ [amazonlinux2-x86_64-standard:4.0](al2/x86_64/standard/4.0)
+ [amazonlinux2-x86_64-standard:5.0](al2/x86_64/standard/5.0)
+ [amazonlinux2-x86_64-standard:corretto8](al2/x86_64/standard/corretto8)
+ [amazonlinux2-x86_64-standard:corretto11](al2/x86_64/standard/corretto11)
+ [amazonlinux2-aarch64-standard:2.0](al2/aarch64/standard/2.0)
+ [amazonlinux2-aarch64-standard:3.0](al2/aarch64/standard/3.0)
+ [amazonlinux-x86_64-lambda-standard:corretto11](al-lambda/x86_64/corretto11)
+ [amazonlinux-x86_64-lambda-standard:corretto17](al-lambda/x86_64/corretto17)
+ [amazonlinux-x86_64-lambda-standard:dotnet6](al-lambda/x86_64/dotnet6)
+ [amazonlinux-x86_64-lambda-standard:go1.21](al-lambda/x86_64/go1.21)
+ [amazonlinux-x86_64-lambda-standard:nodejs18](al-lambda/x86_64/nodejs18)
+ [amazonlinux-x86_64-lambda-standard:python3.11](al-lambda/x86_64/python3.11)
+ [amazonlinux-x86_64-lambda-standard:ruby3.2](al-lambda/x86_64/ruby3.2)
+ [amazonlinux-aarch64-lambda-standard:corretto11](al-lambda/aarch64/corretto11)
+ [amazonlinux-aarch64-lambda-standard:corretto17](al-lambda/aarch64/corretto17)
+ [amazonlinux-aarch64-lambda-standard:dotnet6](al-lambda/aarch64/dotnet6)
+ [amazonlinux-aarch64-lambda-standard:go1.21](al-lambda/aarch64/go1.21)
+ [amazonlinux-aarch64-lambda-standard:nodejs18](al-lambda/aarch64/nodejs18)
+ [amazonlinux-aarch64-lambda-standard:python3.11](al-lambda/aarch64/python3.11)
+ [amazonlinux-aarch64-lambda-standard:ruby3.2](al-lambda/aarch64/ruby3.2)
