# AWS CodeBuild curated Docker images

This repository holds Dockerfiles of official AWS CodeBuild curated Docker images. Please refer to [the AWS CodeBuild User Guide](http://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref.html) for list of environments supported by AWS CodeBuild.

### How to build Docker images

Steps to build Ruby-2.3.1 image

* Run `git clone https://github.com/aws/aws-codebuild-docker-images.git` to download this repository to your local machine
* Run `cd ubuntu/ruby/2.3.1` to change the directory in your local workspace. This is the location of Ruby-2.3.1 Dockerfile with Ubuntu base.
* Run `docker build -t aws/codebuild/ruby-2.3.1 .` to build Docker image locally
* Once succeeded, your can run `docker run -ti aws/codebuild/ruby-2.3.1 bash` to start container running `bash` shell with the ruby-2.3.1 image.


```
$ git clone https://github.com/aws/aws-codebuild-docker-images.git
$ cd aws-codebuild-docker-images
$ cd ubuntu/ruby/2.3.1
$ docker build -t aws/codebuild/ruby-2.3.1 .
```