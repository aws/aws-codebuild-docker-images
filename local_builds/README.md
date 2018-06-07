## AWS CodeBuild Local Builds


You can now locally test and debug your AWS CodeBuild builds using the new CodeBuild local agent.
Previously, if you wanted to test your AWS CodeBuild build, you had to fully configure and run
CodeBuild. Now, you can simulate a CodeBuild environment locally to quickly troubleshoot the
commands and settings located in the BuildSpec file. The agent also allows you to build your application
locally before committing your changes to build on the cloud.

Start by pulling the signed local agent image from [DockerHub](https://hub.docker.com/r/amazon/aws-codebuild-local/):

    docker pull amazon/aws-codebuild-local:latest --disable-content-trust=false


You can verify the SHA matches our [latest release](https://docs.aws.amazon.com/codebuild/latest/userguide/samples.html). Please allow at least an hour after a new version has been pushed for the updated SHA to be reflected in our documentation. 

You will run a docker run command and set three environment variables. Please note the fourth variable is optional:
 1. IMAGE_NAME: your curated environment image 
 2. SOURCE: the absolute path of your local source directory 
 3. ARTIFACTS: the absolute path of an artifact output directory
 4. BUILDSPEC: The path to your buildspec in your source directory

Note that if you want to use an AWS CodeBuild Curated image, you can build it locally on your machine by cloning this repository and performing a docker build on your choice of image.

Command:

    docker run -it -v /var/run/docker.sock/var/run/docker.sock -e "IMAGE_NAME=<Build image>" -e "ARTIFACTS=<Absolute path to your artifact output folder>" -e "SOURCE=<Absolute path to your source directory>" -e "BUILDSPEC=<Relative path to your buildspec override> amazon/aws-codebuild-local

For example on a Linux machine:

    docker run -it -v /var/run/docker.sock:/var/run/docker.sock -e "IMAGE_NAME=awscodebuild/java:openjdk-8" -e "ARTIFACTS=/home/user/testProjectArtifacts" -e "SOURCE=/home/user/testProject" -e "BUILDSPEC=test.yml" amazon/aws-codebuild-local 


Note: If running on a different operating system, your **absolute path** may vary:

    Linux: /home/user/...
    MacOS: /Users/user/...

