#!/bin/bash

function allOSRealPath() {
    case $1 in
        /* ) echo "$1"; exit;;
        *  ) echo "$PWD/${1#./}"; exit;;
    esac
}

function usage {
    echo "usage: codebuild_build.sh [-i image_name] [-a artifact_output_directory] [options]"
    echo "Required:"
    echo "  -i        Used to specify the customer build container image."
    echo "  -a        Used to specify an artifact output directory."
    echo "Options:"
    echo "  -s        Used to specify a source directory. Defaults to the current working directory."
    echo "  -c        Use the AWS configuration and credentials from your local host. This includes ~/.aws and any AWS_* environment variables."
    echo "  -b        Used to specify a buildspec override file. Defaults to buildspec.yml in the source directory."
    echo "  -e        Used to specify a file containing environment variables."
    echo "            Environment variable file format:"
    echo "               * Expects each line to be in VAR=VAL format"
    echo "               * Lines beginning with # are processed as comments and ignored"
    echo "               * Blank lines are ignored"
    echo "               * File can be of type .env or .txt"
    echo "               * There is no special handling of quotation marks, meaning they will be part of the VAL"
    exit 1
}

image_flag=false
artifact_flag=false
awsconfig_flag=false

while getopts "ci:a:s:b:e:h" opt; do
    case $opt in
        i  ) image_flag=true; image_name=$OPTARG;;
        a  ) artifact_flag=true; artifact_dir=$OPTARG;;
        b  ) buildspec=$OPTARG;;
        c  ) awsconfig_flag=true;;
        s  ) source_dir=$OPTARG;;
        e  ) environment_variable_file=$OPTARG;;
        h  ) usage; exit;;
        \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Invalid option: -$OPTARG" >&2; exit 1;;
    esac
done

if  ! $image_flag
then
    echo "The image name flag (-i) must be included for a build to run" >&2
fi

if  ! $artifact_flag
then
    echo "The artifact directory (-a) must be included for a build to run" >&2
fi

if  ! $image_flag ||  ! $artifact_flag
then
    exit 1
fi

if [ -z "$source_dir" ]
then
    source_dir="$(pwd)"
else
    source_dir=$(allOSRealPath $source_dir)
fi

docker_command="docker run -it -v /var/run/docker.sock:/var/run/docker.sock -e \
    \"IMAGE_NAME=$image_name\" -e \
    \"ARTIFACTS=$(allOSRealPath $artifact_dir)\" -e \
    \"SOURCE=$source_dir\""

if [ -n "$buildspec" ]
then
    docker_command+=" -e \"BUILDSPEC=$(allOSRealPath $buildspec)\""
fi

if [ -n "$environment_variable_file" ]
then
    environment_variable_file_path=$(allOSRealPath "$environment_variable_file")
    environment_variable_file_dir=$(dirname "$environment_variable_file_path")
    environment_variable_file_basename=$(basename "$environment_variable_file")
    docker_command+=" -v \"$environment_variable_file_dir:/LocalBuild/envFile/\" -e \"ENV_VAR_FILE=$environment_variable_file_basename\""
fi

if  $awsconfig_flag
then
    if [ -d "$HOME/.aws" ]
    then
        docker_command+=" -e \"AWS_CONFIGURATION=$HOME/.aws\""
    else
        docker_command+=" -e \"AWS_CONFIGURATION=NONE\""
    fi
    docker_command+="$(env | grep ^AWS_ | while read -r line; do echo " -e \"$line\""; done )"
fi

docker_command+=" amazon/aws-codebuild-local:latest"

# Note we do not expose the AWS_SECRET_ACCESS_KEY or the AWS_SESSION_TOKEN
exposed_command=$docker_command
secure_variables=( "AWS_SECRET_ACCESS_KEY=" "AWS_SESSION_TOKEN=")
for variable in "${secure_variables[@]}"
do
    exposed_command="$(echo $exposed_command | sed "s/\($variable\)[^ ]*/\1********\"/")"
done

echo "Build Command:"
echo ""
echo $exposed_command
echo ""

eval $docker_command
