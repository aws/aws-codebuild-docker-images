#!/bin/sh

function usage {
    echo "usage: codebuild_build.sh [-i image_name] [-a artifact_output_directory] [options]"
    echo "Required:"
    echo "  -i        Used to specify the customer build container image."
    echo "  -a        Used to specify an artifact output directory."
    echo "Options:"
    echo "  -s        Used to specify a source directory. Defaults to the current working directory."
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

while getopts "i:a:s:b:e:h" opt; do
    case $opt in
        i  ) image_flag=true; image_name=$OPTARG;;
        a  ) artifact_flag=true; artifact_dir=$OPTARG;;
        b  ) buildspec=$OPTARG;;
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
    source_dir=$(realpath $source_dir)
fi

docker_command="docker run -it -v /var/run/docker.sock:/var/run/docker.sock -e \
    \"IMAGE_NAME=$image_name\" -e \
    \"ARTIFACTS=$(realpath $artifact_dir)\" -e \
    \"SOURCE=$source_dir\""

if [ -n "$buildspec" ]
then
    docker_command+=" -e \"BUILDSPEC=$buildspec\""
fi

if [ -n "$environment_variable_file" ]
then
    docker_command+=" -v $(dirname $(realpath $environment_variable_file)):/LocalBuild/envFile/ -e \"ENV_VAR_FILE=$(basename $environment_variable_file)\""
fi

docker_command+=" amazon/aws-codebuild-local:latest"

echo "Build Command:"
echo ""
echo $docker_command
echo ""

eval $docker_command