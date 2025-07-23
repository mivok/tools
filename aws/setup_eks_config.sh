#!/usr/bin/env bash

usage() {
    echo "Usage: $0 [OPTIONS...] PROFILE REGION"
    echo
    echo "Sets up a kubeconfig file for the specified EKS clusters."
    echo
    echo "Options:"
    echo "  -c, --cluster-name CLUSTER_NAME  Specify the EKS cluster name"
    echo
    echo "  -f, --force         Don't skip existing kubeconfig files"
    echo "  -h, --help          Show this help message and exit"
    echo "  -n, --dry-run       Show what would be run without executing it"
    echo
    echo "If a cluster name isn't specified, all clusters in the region"
    echo "will be set up."
    exit 254
}

# Parse command line options
FORCE=
DRY_RUN=
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--cluster-name)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        -n|--dry-run)
            DRY_RUN=1
            shift
            ;;
        *)
            break
            ;;
    esac
done

PROFILE="$1"
REGION="$2"

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
        list-clusters --query "clusters[].[@]" --output text)
fi

for CLUSTER_NAME in "${CLUSTERS[@]}"; do
    echo "Setting up kubeconfig for cluster: $CLUSTER_NAME"
    # Strip any trailing -eks-cluster or -cluster from the cluster name to get a
    # friendly name used for context and config file names
    FRIENDLY_NAME="${CLUSTER_NAME/-eks-cluster/}"
    FRIENDLY_NAME="${FRIENDLY_NAME/-cluster/}"

    export KUBECONFIG="$HOME/.kube/${FRIENDLY_NAME}.config"

    if [[ -e "$HOME/.kube/${FRIENDLY_NAME}.config" && -z "$FORCE" ]]; then
        echo "Skipping existing kubeconfig file: $KUBECONFIG"
        continue
    fi

    CMD=(
        aws eks
        --profile "$PROFILE"
        --region "$REGION"
        update-kubeconfig
        --name "$CLUSTER_NAME"
        --alias "$FRIENDLY_NAME"
    )

    if [[ -n "$DRY_RUN" ]]; then
        echo "Dry run: ${CMD[*]}"
    else
        "${CMD[@]}"
    fi
done
