#!/usr/bin/env bash
# Helper for setting up a kubernetes config from EKS clusters

usage() {
    echo "Usage: $0 PROFILE REGION [CLUSTER_NAME]"
    echo
    echo "Sets up a kubeconfig file for the specified EKS clusters."
    echo
    echo "If a cluster name isn't specified, all clusters in the region"
    echo "will be set up."
    exit 254
}

PROFILE="$1"
REGION="$2"
CLUSTER_NAME="$3"

if [[ -z "$PROFILE" || -z "$REGION" ]]; then
    usage
fi

# Get the list of clusters to process
CLUSTERS=()
if [[ -n "$CLUSTER_NAME" ]]; then
    CLUSTERS+=("$CLUSTER_NAME")
else
    while IFS= read -r CLUSTER; do
        CLUSTERS+=("$CLUSTER")
    done < <(aws eks --profile "$PROFILE" --region "$REGION" \
        list-clusters --query "clusters[]" --output text)
fi

for CLUSTER_NAME in "${CLUSTERS[@]}"; do
    echo "Setting up kubeconfig for cluster: $CLUSTER_NAME"
    # Strip any trailing -eks-cluster or -cluster from the cluster name to get a
    # friendly name used for context and config file names
    FRIENDLY_NAME="${CLUSTER_NAME/-eks-cluster/}"
    FRIENDLY_NAME="${FRIENDLY_NAME/-cluster/}"

    aws eks \
        --profile "$PROFILE" \
        --region "$REGION" \
        update-kubeconfig \
        --name "$CLUSTER_NAME" \
        --alias "$FRIENDLY_NAME" \
        --kubeconfig "$HOME/.kube/${FRIENDLY_NAME}.config"
done
