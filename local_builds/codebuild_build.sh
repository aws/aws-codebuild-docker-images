#!/bin/bash

function allOSRealPath() {
    if isOSWindows
    then
        path=""
        case $1 in
            .* ) path="$PWD/${1#./}" ;;
            /* ) path="$1" ;;
            *  ) path="/$1" ;;
        esac

        echo "/$path" | sed -e 's/\\/\//g' -e 's/://' -e 's/./\U&/3'
    else
        case $1 in
            /* ) echo "$1"; exit;;
            *  ) echo "$PWD/${1#./}"; exit;;
        esac
    fi
}

function isOSWindows() {
    if [ $OSTYPE == "msys" ]
    then
        return 0
    else
        return 1
    fi
}

function usage {
    echo "usage: codebuild_build.sh [-i image_name] [-a artifact_output_directory] [options]"
    echo "Required:"
    echo "  -i        Used to specify the customer build container image."
    echo "  -a        Used to specify an artifact output directory."
    echo "Options:"
    echo "  -l IMAGE  Used to override the default local agent image."
    echo "  -r        Used to specify a report output directory."
    echo "  -s        Used to specify source information. Defaults to the current working directory for primary source."
    echo "               * First (-s) is for primary source"
    echo "               * Use additional (-s) in <sourceIdentifier>:<sourceLocation> format for secondary source"
    echo "               * For sourceIdentifier, use a value that is fewer than 128 characters and contains only alphanumeric characters and underscores"
    echo "  -c        Use the AWS configuration and credentials from your local host. This includes ~/.aws and any AWS_* environment variables."
    echo "  -p        Used to specify the AWS CLI Profile."
    echo "  -b FILE   Used to specify a buildspec override file. Defaults to buildspec.yml in the source directory."
    echo "  -m        Used to mount the source directory to the customer build container directly."
    echo "  -d        Used to run the build container in docker privileged mode."
    echo "  -e FILE   Used to specify a file containing environment variables."
    echo "            (-e) File format expectations:"
    echo "               * Each line is in VAR=VAL format"
    echo "               * Lines beginning with # are processed as comments and ignored"
    echo "               * Blank lines are ignored"
    echo "               * File can be of type .env or .txt"
    echo "               * There is no special handling of quotation marks, meaning they will be part of the VAL"
    exit 1
}

image_flag=false
artifact_flag=false
awsconfig_flag=false
mount_src_dir_flag=false
docker_privileged_mode_flag=false

while getopts "cmdi:a:r:s:b:e:l:p:h" opt; do
    case $opt in
        i  ) image_flag=true; image_name=$OPTARG;;
        a  ) artifact_flag=true; artifact_dir=$OPTARG;;
        r  ) report_dir=$OPTARG;;
        b  ) buildspec=$OPTARG;;
        c  ) awsconfig_flag=true;;
        m  ) mount_src_dir_flag=true;;
        d  ) docker_privileged_mode_flag=true;;
        s  ) source_dirs+=("$OPTARG");;
        e  ) environment_variable_file=$OPTARG;;
        l  ) local_agent_image=$OPTARG;;
        p  ) aws_profile=$OPTARG;;
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

docker_command="docker run -it "
if isOSWindows
then
    docker_command+="-v //var/run/docker.sock:/var/run/docker.sock -e "
else
    docker_command+="-v /var/run/docker.sock:/var/run/docker.sock -e "
fi

docker_command+="\"IMAGE_NAME=$image_name\" -e \
    \"ARTIFACTS=$(allOSRealPath "$artifact_dir")\""

if [ -n "$report_dir" ]
then
    docker_command+=" -e \"REPORTS=$(allOSRealPath "$report_dir")\""
fi

if [ -z "$source_dirs" ]
then
    docker_command+=" -e \"SOURCE=$(allOSRealPath "$PWD")\""
else
    for index in "${!source_dirs[@]}"; do
        if [ $index -eq 0 ]
        then
            docker_command+=" -e \"SOURCE=$(allOSRealPath "${source_dirs[$index]}")\""
        else
            identifier=${source_dirs[$index]%%:*}
            src_dir=$(allOSRealPath "${source_dirs[$index]#*:}")

            docker_command+=" -e \"SECONDARY_SOURCE_$index=$identifier:$src_dir\""
        fi
    done
fi

if [ -n "$buildspec" ]
then
    docker_command+=" -e \"BUILDSPEC=$(allOSRealPath "$buildspec")\""
fi

if [ -n "$environment_variable_file" ]
then
    environment_variable_file_path=$(allOSRealPath "$environment_variable_file")
    environment_variable_file_dir=$(dirname "$environment_variable_file_path")
    environment_variable_file_basename=$(basename "$environment_variable_file")
    docker_command+=" -v \"$environment_variable_file_dir:/LocalBuild/envFile/\" -e \"ENV_VAR_FILE=$environment_variable_file_basename\""
fi

if [ -n "$local_agent_image" ]
then
    docker_command+=" -e \"LOCAL_AGENT_IMAGE_NAME=$local_agent_image\""
fi

if $awsconfig_flag
then
    if [ -d "$HOME/.aws" ]
    then
        configuration_file_path=$(allOSRealPath "$HOME/.aws")
        docker_command+=" -e \"AWS_CONFIGURATION=$configuration_file_path\""
    else
        docker_command+=" -e \"AWS_CONFIGURATION=NONE\""
    fi

    if [ -n "$aws_profile" ]
    then
        docker_command+=" -e \"AWS_PROFILE=$aws_profile\""
    fi

    docker_command+="$(env | grep ^AWS_ | while read -r line; do echo " -e \"$line\""; done )"
fi

if $mount_src_dir_flag
then
    docker_command+=" -e \"MOUNT_SOURCE_DIRECTORY=TRUE\""
fi

if $docker_privileged_mode_flag
then
    docker_command+=" -e \"DOCKER_PRIVILEGED_MODE=TRUE\""
fi

if isOSWindows
then
    docker_command+=" -e \"INITIATOR=$USERNAME\""
else
    docker_command+=" -e \"INITIATOR=$USER\""
fi

if [ -n "$local_agent_image" ]
then
    docker_command+=" $local_agent_image"
else
    docker_command+=" public.ecr.aws/codebuild/local-builds:latest"
fi

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
