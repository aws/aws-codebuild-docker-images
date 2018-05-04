## AWS CodeBuild Local Builds


You can now locally test and debug your AWS CodeBuild builds using the new CodeBuild local agent.
Previously, if you wanted to test your AWS CodeBuild build, you had to fully configure and run
CodeBuild. Now, you can simulate a CodeBuild environment locally to quickly troubleshoot the
commands and settings located in the BuildSpec file. The agent also allows you to build your application
locally before committing your changes to build on the cloud.

Start by pulling the signed local agent image from [DockerHub](https://hub.docker.com/r/amazon/aws-codebuild-local/):

    docker pull amazon/aws-codebuild-local:latest --disable-content-trust=false

You will run a docker run command and set three environment variables:

 1. IMAGE_NAME: your curated environment image 
 2. SOURCE: your local source directory 
 3. ARTIFACTS: an artifact output directory

Note that if you want to use an AWS CodeBuild Curated image, you can build it locally on your machine by cloning this repository and performing a docker build on your choice of image.

Command:

    docker run -it -v /var/run/docker.sock/var/run/docker.sock -e "IMAGE_NAME=<Build image>" -e "ARTIFACTS=<Absolute path to your artifact output folder>" -e "SOURCE=<Absolute path to your source directory>" amazon/aws-codebuild-local

For example:

    docker run -it -v /var/run/docker.sock:/var/run/docker.sock -e "IMAGE_NAME=awscodebuild/java:openjdk-8" -e "ARTIFACTS=/home/user/testProjectArtifacts" -e "SOURCE=/home/user/testProject" amazon/aws-codebuild-local 