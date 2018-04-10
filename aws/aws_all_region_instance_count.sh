#!/bin/bash
REGIONS=$(aws --region us-east-1 ec2 describe-regions |
    jq -r '.Regions[].RegionName')


for REGION in $REGIONS; do
    echo -n "$REGION: "
    aws --region $REGION ec2 describe-instances \
        --query 'length(Reservations[].Instances[].InstanceId)'
done
