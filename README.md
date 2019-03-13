# AWS CodeBuild curated Docker images

This repository holds Dockerfiles of official AWS CodeBuild curated Docker images. Please refer to [the AWS CodeBuild User Guide](http://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref.html) for list of environments supported by AWS CodeBuild.

![Build Status](https://codebuild.us-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiSkJibVVQVEpvUms1cmw3YVlnU1hSdkpBQ0c5SFgyTkJXMFBFdEU2SWtySHREcUlUVlRhbW4zMEd3NlhsOWIzUWgvRkxhUWVSSTFPZGNNakNHRVNLalY0PSIsIml2UGFyYW1ldGVyU3BlYyI6IlV0QjBRZXRvS0F5dE5vbTciLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master)

The master branch will sometimes have changes that are still in the process of being released in AWS CodeBuild.  See the latest released versions of the Dockerfiles ![here](https://github.com/aws/aws-codebuild-docker-images/releases).

### How to build Docker images

Steps to build Ruby 2.3.1 image

* Run `git clone https://github.com/aws/aws-codebuild-docker-images.git` to download this repository to your local machine
* Run `cd ubuntu/ruby/2.3.1` to change the directory in your local workspace. This is the location of the Ruby 2.3.1 Dockerfile with Ubuntu 14.04 base.
* Run `docker build -t aws/codebuild/ruby:2.3.1 .` to build Docker image locally

To poke around in the image interactively, build it and run:
`docker run -it --entrypoint sh aws/codebuild/ruby:2.3.1 -c bash`

To let the Docker daemon start up in the container, build it and run:
`docker run -it --privileged aws/codebuild/ruby:2.3.1 bash`

```
$ git clone https://github.com/aws/aws-codebuild-docker-images.git
$ cd aws-codebuild-docker-images
$ cd ubuntu/ruby/2.3.1
$ docker build -t aws/codebuild/ruby:2.3.1 .
$ docker run -it --entrypoint sh aws/codebuild/ruby:2.3.1 -c bash
```

### Image maintenance

Some of the images in this repository are no longer actively maintained by AWS CodeBuild and may no longer build successfully.  These images will not receive any further updates.  They remain in this repository as a reference for the contents of these images that were previously released by CodeBuild.

The following images are actively maintained by AWS CodeBuild, and are listed in the CodeBuild console.

+ [standard 1.0](ubuntu/standard/1.0)

