#!/usr/bin/env bash

echo "Launched email script!"

# Usage: ./checkAndSendBuildErrorEmail.sh <exit status> <Name of step>
EXIT_STATUS=$1
FAILED_STEP=$2

if [ $EXIT_STATUS -ne "0" ]; then

    # Get the pipeline name (take "codepipeline:" off the front of it (13 characters)
    PIPELINE_PROJECT_NAME=${CODEBUILD_INITIATOR:13}
    AWS_REGION=${AWS_DEFAULT_REGION}
    PIPELINE_URL="https://$AWS_REGION.console.aws.amazon.com/codepipeline/home?region=$AWS_REGION#/view/$PIPELINE_PROJECT_NAME"

    SUBJECT="$PIPELINE_PROJECT_NAME failed $FAILED_STEP"
    MESSAGE="To see full output, see here: $PIPELINE_URL"

    echo "Intiated by pipeline: $CODEBUILD_INITIATOR"
    echo "Repo name: $REPO_NAME"
    echo "Source Version: $CODEBUILD_RESOLVED_SOURCE_VERSION"

    echo "Preparing to send email..."
    
    # determine who the email should go to
    # This github token is encrypted with AWS KMS and the key is controlled with AWS IAM permissions
    GITHUB_OAUTH_TOKEN=$(aws ssm get-parameters --names github.oathtoken --with-decryption | jq -r .Parameters[0].Value)
    #EMAIL=$(aws codecommit get-commit --repository-name $REPO_NAME --commit-id $CODEBUILD_RESOLVED_SOURCE_VERSION | jq -r .commit.committer.email | tr '[:upper:]' '[:lower:]')
    EMAIL=$(curl -H "Authorization: token $GITHUB_OAUTH_TOKEN" https://api.github.com/repos/bio-rad-lsg-sw/$REPO_NAME/commits/$CODEBUILD_RESOLVED_SOURCE_VERSION | jq -r .commit.author.email | tr '[:upper:]' '[:lower:]')

    echo "Sending email to: $EMAIL"

    aws ses send-email --from $EMAIL --to $EMAIL --subject "$SUBJECT" --text "$MESSAGE"

else
    echo "No email to send!"
fi
exit $EXIT_STATUS
