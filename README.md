# AWS CodeBuild curated Docker images

This repository holds Dockerfiles of official AWS CodeBuild curated Docker images. Please refer to [the AWS CodeBuild User Guide](http://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref.html) for list of environments supported by AWS CodeBuild.

![Build Status](https://codebuild.us-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiSkJibVVQVEpvUms1cmw3YVlnU1hSdkpBQ0c5SFgyTkJXMFBFdEU2SWtySHREcUlUVlRhbW4zMEd3NlhsOWIzUWgvRkxhUWVSSTFPZGNNakNHRVNLalY0PSIsIml2UGFyYW1ldGVyU3BlYyI6IlV0QjBRZXRvS0F5dE5vbTciLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master)

The master branch will sometimes have changes that are still in the process of being released in AWS CodeBuild.  See the latest released versions of the Dockerfiles [here](https://github.com/aws/aws-codebuild-docker-images/releases)

### How to build Docker images

Steps to build Standard 2.0 image

* Run `git clone https://github.com/aws/aws-codebuild-docker-images.git` to download this repository to your local machine
* Run `cd ubuntu/standard/2.0` to change the directory in your local workspace. This is the location of the Standard 2.0 Dockerfile with Ubuntu base.
* Run `docker build -t aws/codebuild/standard:2.0 .` to build Docker image locally

To poke around in the image interactively, build it and run:
`docker run -it --entrypoint sh aws/codebuild/standard:2.0 -c bash`

To let the Docker daemon start up in the container, build it and run:
`docker run -it --privileged aws/codebuild/standard:2.0 bash`

```
$ git clone https://github.com/aws/aws-codebuild-docker-images.git
$ cd aws-codebuild-docker-images
$ cd ubuntu/standard/2.0
$ docker build -t aws/codebuild/standard:2.0 .
$ docker run -it --entrypoint sh aws/codebuild/standard:2.0 -c bash
```

### Image maintenance

Some of the images in this repository are no longer actively maintained by AWS CodeBuild and may no longer build successfully.  These images will not receive any further updates.  They remain in this repository as a reference for the contents of these images that were previously released by CodeBuild.

The following images are actively maintained by AWS CodeBuild, and are listed in the CodeBuild console.

+ [standard 2.0](ubuntu/standard/2.0)
+ [standard 3.0](ubuntu/standard/3.0)
+ [standard 4.0](ubuntu/standard/4.0)
+ [amazonlinux2-x86_64-standard:1.0](al2/x86_64/standard/1.0)
+ [amazonlinux2-x86_64-standard:2.0](al2/x86_64/standard/2.0)
+ [amazonlinux2-x86_64-standard:3.0](al2/x86_64/standard/3.0)
+ [amazonlinux2-aarch64-standard:1.0](al2/aarch64/standard/1.0)
