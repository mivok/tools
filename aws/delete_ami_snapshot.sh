#!/usr/bin/env bash
# Deletes an AMI along with its associated snapshot

FORCE_YES=
REGION=

usage() {
    echo "Usage: $0 [-y] [-r REGION] AMI_ID"
    exit 254
}

while getopts ":yr:" opt; do
    case $opt in
        y)  FORCE_YES=1
            ;;
        r)  REGION="$OPTARG"
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

AMI=$1

OPTS=()
if [[ -n $REGION ]]; then
    OPTS+=(--region "$REGION")
fi

SNAPS=$(aws "${OPTS[@]}" ec2 describe-images --image-ids="$AMI" | \
    jq -r '.Images[].BlockDeviceMappings[].Ebs.SnapshotId')

echo "=> Found snapshots for ami $AMI: $SNAPS"

echo "=> Deleting AMI $AMI"
confirm || exit 1
aws "${OPTS[@]}" ec2 deregister-image --image-id "$AMI"

for SNAP in $SNAPS; do
    echo "=> Deleting snapshot $SNAP"
    confirm || exit 1
    aws "${OPTS[@]}" ec2 delete-snapshot --snapshot-id "$SNAP"
done
