#!/bin/bash
# Search for instances matching a given name
REGION=
PROFILE=
EXACTMATCH=

usage() {
    echo "Usage: $0 [-r REGION] [-p PROFILE] PATTERN"
    echo
    echo "  -r REGION  -- Specify AWS region (Default: $REGION)"
    echo "  -p PROFILE -- Specify credentials profile (Default: $PROFILE)"
    echo "  -x         -- Only return exact matches (Default: partial)"
    exit 1
}

while getopts ":p:r:x" opt; do
    case $opt in
        r)  REGION="$OPTARG"
            ;;
        p)  PROFILE="$OPTARG"
            ;;
        x)  EXACTMATCH=1
            ;;
        *)  echo "Invalid option -- '$OPTARG'"
            usage
            ;;
    esac
done
shift $((OPTIND-1))

PATTERN="$1"

[[ -z $1 ]] && usage

if [[ -z $EXACTMATCH ]]; then
    PATTERN="*$PATTERN*"
fi

OPTS=()
if [[ -n $PROFILE ]]; then
    OPTS+=(--profile "$PROFILE")
fi

if [[ -n $REGION ]]; then
    OPTS+=(--region "$REGION")
fi

aws "${OPTS[@]}" ec2 describe-instances \
    --filters "Name=tag:Name,Values=$PATTERN" | \
    jq -r '[
        .Reservations[].Instances[] |
            [
                .InstanceId,
                .PrivateIpAddress,
                [.Tags[] | select(.Key == "Name") | .Value][0]
            ]
        ] | sort_by(.[2]) | .[] | @tsv'
