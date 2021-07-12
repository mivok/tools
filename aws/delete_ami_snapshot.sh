#!/usr/bin/env bash
# Deletes an AMI or several AMIs along with their associated snapshots

FORCE_YES=
REGION=

usage() {
    echo "Usage: $0 [-y] [-p PROFILE] [-r REGION] AMI_ID|SEARCH_TERM"
    echo ""
    echo "Deletes an AMI along with its snapsnot, or deletes all AMIs matching"
    echo "the given search term."
    echo
    echo "If the pattern begins with 'ami-', then it's treated as a single"
    echo "AMI. Otherwise, all AMIs named with the search term will be"
    echo "deleted instead."
    exit 254
}

while getopts ":yp:r:" opt; do
    case $opt in
        y)  FORCE_YES=1
            ;;
        r)  REGION="$OPTARG"
            ;;
        p)  export AWS_PROFILE="$OPTARG"
            ;;
        :)  echo "Option missing required argument -- '$OPTARG'" 
            usage
            ;;
        *)  echo "Invalid option -- '$OPTARG'"
            usage
            ;;
    esac
done
shift $((OPTIND-1))

[[ -z $1 ]] && usage

# shellcheck disable=SC2120
confirm() {
    [[ -n $FORCE_YES ]] && return 0
    local PROMPT=$1
    [[ -z $PROMPT ]] && PROMPT="OK to continue?"
    local REPLY=
    while [[ ! $REPLY =~ ^[YyNn]$ ]]; do
        echo -n "$PROMPT (y/n) "
        read -r
    done
    # The result of this comparison is the return value of the function
    [[ $REPLY =~ ^[Yy]$ ]]
}

OPTS=()
if [[ -n $REGION ]]; then
    OPTS+=(--region "$REGION")
fi

if [[ "$1" =~ ^ami- ]]; then
    FILTER_OPT="--image-ids=$1"
else
    FILTER_OPT="--filters=Name=name,Values=*$1*"
fi

MATCHES=$(aws "${OPTS[@]}" ec2 describe-images --owners self "$FILTER_OPT" |
    jq -r '.Images[] | [.ImageId, .Name] | @tsv')

echo "=> Will delete the following AMIs"
echo "$MATCHES"
confirm || exit 1

while IFS=$'\t' read -r AMI NAME; do
    echo "=> Deleting AMI $AMI ($NAME)"

    SNAPS=$(aws "${OPTS[@]}" ec2 describe-images --image-ids="$AMI" | \
        jq -r '.Images[].BlockDeviceMappings[].Ebs.SnapshotId')

    echo "===> Found snapshots for ami $AMI: $SNAPS"

    echo "===> Deregistering $AMI"
    aws "${OPTS[@]}" ec2 deregister-image --image-id "$AMI"

    for SNAP in $SNAPS; do
        echo "===> Deleting snapshot $SNAP"
        aws "${OPTS[@]}" ec2 delete-snapshot --snapshot-id "$SNAP"
    done
done <<< "$MATCHES"
