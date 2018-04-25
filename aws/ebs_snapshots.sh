#!/bin/bash
# Prints the most recent EBS snapshot for matching instances
TAG="$1"
VALUES="$2"

if [[ -z $TAG || -z $VALUES ]]; then
    echo "Usage: $0 TAG VALUE[,VALUE,...]"
    echo "List the most recent EBS snapshots for the matching instances"
    exit 1
fi

VOLUME_IDS=$(aws ec2 describe-instances \
    --filter "Name=tag:$TAG,Values=$VALUES" | \
    jq -r '.Reservations[].Instances[].BlockDeviceMappings[].Ebs.VolumeId')

for VOL in $VOLUME_IDS; do
    aws ec2 describe-snapshots --filters "Name=volume-id,Values=$VOL" | \
        jq -r '.Snapshots | sort_by(.StartTime) | last |
            [.SnapshotId, .StartTime, .State] | @tsv'
done
