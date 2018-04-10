#!/bin/bash
# Shows you information on an instance given its ID
REGION=
PROFILE=
VERBOSE=

usage() {
    echo "Usage: $0 [-v] [-r REGION] [-p PROFILE] INSTANCE_ID"
    echo
    echo "  -r REGION  -- Specify AWS region (Default: us-east-1)"
    echo "  -p PROFILE -- Specify credentials profile (Default: default)"
    echo "  -v -- Verbose. Print the raw json returned by the API"
}

while getopts ":p:r:vh" opt; do
    case $opt in
        r)  REGION="$OPTARG"
            ;;
        p)  PROFILE="$OPTARG"
            ;;
        v)  VERBOSE=1
            ;;
        h)  usage
            exit 0
            ;;
        *)  echo "Invalid option -- '$OPTARG'"
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

INSTANCE_ID="$1"

if [[ -z $1 ]]; then
    usage
    exit 1
fi

OPTS=()
if [[ -n $PROFILE ]]; then
    OPTS+=(--profile "$PROFILE")
fi

if [[ -n $REGION ]]; then
    OPTS+=(--region "$REGION")
fi

if [[ -n $VERBOSE ]]; then
    aws "${OPTS[@]}" ec2 describe-instances --instance-ids "$INSTANCE_ID"
else
    aws "${OPTS[@]}" ec2 describe-instances --instance-ids "$INSTANCE_ID" | \
    jq -r '[
        .Reservations[].Instances[] |
            [
                .InstanceId,
                .PrivateIpAddress,
                [.Tags[] | select(.Key == "Name") | .Value][0]
            ]
        ] | sort_by(.[2]) | .[] | @tsv'
fi
