#!/bin/bash
# Run a docker container with tfenv installed, for running older versions of
# terraform.
#
# Note: this is isn't needed for terraform 1.X. It is mostly for use on an M1
# Mac where earlier versions of terraform weren't available for arm.
#
# Usage:
#
# * Log in to AWS (aws sso login --profile cudasec)
# * export AWS_PROFILE=cuda-essprod (or whatever profile you want)
# * Run this command
# * Run tfenv install (or tfenv use VERSION)
# * Terraform should be available for use

# Older versions of terraform don't necessarily support AWS SSO, so manually
# export the credentials
if [[ -n "$AWS_PROFILE" ]]; then
    echo "Exporting AWS credentials for profile: $AWS_PROFILE"
    eval "$(aws configure export-credentials --format env)"
else
    echo "No profile set, skipping AWS credential export"
fi

docker run -it --rm \
    --platform linux/amd64 \
    -v "$PWD:/terraform" \
    -v "$HOME/.aws:/root/.aws:ro" \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_CA_BUNDLE \
    -e AWS_CLI_FILE_ENCODING \
    -e AWS_CONFIG_FILE \
    -e AWS_DEFAULT_OUTPUT \
    -e AWS_DEFAULT_PROFILE \
    -e AWS_DEFAULT_REGION \
    -e AWS_PAGER \
    -e AWS_PROFILE \
    -e AWS_ROLE_SESSION_NAME \
    -e AWS_SDK_CONFIG \
    -e AWS_SECRET_ACCESS_KEY \
    -e AWS_SESSION_TOKEN \
    -e AWS_SHARED_CREDENTIALS_FILE \
    -e AWS_STS_REGIONAL_ENDPOINTS \
    -w /terraform \
    wolfsoftwareltd/tfenv-alpine:latest
    "$@"
