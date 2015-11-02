#!/bin/bash
# Shows you information on an instance given its ID
REGION=us-east-1
PROFILE=default
VERBOSE=

while getopts ":p:r:v" opt; do
    case $opt in
        r)  REGION="$OPTARG"
            ;;
        p)  PROFILE="$OPTARG"
            ;;
        v)  VERBOSE=1
            ;;
        *)  echo "Invalid option -- '$OPTARG'"
            usage
            ;;
    esac
done
shift $((OPTIND-1))

INSTANCE_ID="$1"

if [[ -z $1 || -n $HELP ]]; then
    echo "Usage: $0 [-v] [-r REGION] [-p PROFILE] INSTANCE_ID"
    echo
    echo "  -r REGION  -- Specify AWS region (Default: us-east-1)"
    echo "  -p PROFILE -- Specify credentials profile (Default: default)"
    echo "  -v -- Verbose. Print the raw json returned by the API"
    exit 1
fi

if [[ -n $VERBOSE ]]; then
    aws --profile "$PROFILE" ec2 describe-instances --region "$REGION" \
        --instance-ids "$INSTANCE_ID"
else
    aws --profile "$PROFILE" ec2 describe-instances --region "$REGION" \
        --instance-ids "$INSTANCE_ID" | \
        jq -r '.Reservations[].Instances[].Tags[] | "\(.Key): \(.Value)"'
fi
