#!/bin/bash
# Gets one or more AKS cluster kubeconfigs and saves them.
#
# You can specify the subscripton. If you leave out the subscription, it will
# use the current subscription.

usage() {
  echo "Usage: $0 [OPTIONS...]"
  echo
  echo "Options:"
  echo "  -s, --subscription SUBSCRIPTION      Specify the Azure subscription"
  echo "  -g, --resource-group RESOURCE_GROUP  Specify the resource group"
  echo "  -c, --cluster-name CLUSTER_NAME      Specify the AKS cluster name"
  echo
  echo "  -f, --force             Don't skip existing kubeconfig files"
  echo "  -h, --help              Show this help message and exit"
  echo "  -n, --dry-run           Show what would be run without executing it"
  echo "  --no-convert-kubeconfig Do not convert kubeconfig to use azurecli"
  echo
  echo "If you do not specify a cluster name, the script will loop through all"
  echo "clusters in the specified subscription and set up kubeconfigs for each."
  echo
  echo "If you do not specify a subscription, the script will loop through all"
  echo "subscriptions in your Azure account and set up kubeconfigs for all AKS"
  echo "clusters in each subscription."
  echo
  echo "If you specify a cluster name, but not a resource group, the script"
  echo "will assume the resource group is the same as the cluster name."
  echo
  echo "If you do not include the --no-convert-kubeconfig flag then the script"
  echo "will also convert the kubeconfig to use azurecli authentication,"
  echo "which lets you run 'az login' to authenticate to the cluster and not"
  echo "have to copy and paste a device code into the browser."
  exit 1
}

DRY_RUN=
DONT_CONVERT_KUBECONFIG=
FORCE=

while [[ "$1" == -* ]]; do
    case "$1" in
        --help|-h)
            usage
            ;;
        --dry-run|-n)
            DRY_RUN=1
            shift
            ;;
        --force|-f)
            FORCE=1
            shift
            ;;
        --resource-group|-g)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        --cluster-name|-c)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        --subscription|-s)
            SUBSCRIPTION="$2"
            shift 2
            ;;
        --no-convert-kubeconfig)
            export DONT_CONVERT_KUBECONFIG=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

setup_aks_config() {
    local SUBSCRIPTION="$1"
    local CLUSTER_NAME="$2"
    local RESOURCE_GROUP="$3"
    echo "## Setting up kubeconfig for cluster: $CLUSTER_NAME"

    export KUBECONFIG="$HOME/.kube/$CLUSTER_NAME.config"

    if [[ -z "$FORCE" && -f "$KUBECONFIG" ]]; then
        echo "Kubeconfig file $KUBECONFIG already exists, skipping."
        echo "Use --force to overwrite."
        return
    fi

    CMD=(
        az aks get-credentials
        --subscription "$SUBSCRIPTION"
        --resource-group "$RESOURCE_GROUP"
        --name "$CLUSTER_NAME"
        --file "$KUBECONFIG"
    )

    if [[ -n "$DRY_RUN" ]]; then
        echo "${CMD[@]}"
    else
        "${CMD[@]}"
    fi

    if [[ -z "$DONT_CONVERT_KUBECONFIG" ]]; then
        echo "## Converting kubeconfig to use azurecli authentication"
        CONVERT_CMD=(kubelogin convert-kubeconfig -l azurecli)
        if [[ -n "$DRY_RUN" ]]; then
            echo "${CONVERT_CMD[@]}"
        else
            "${CONVERT_CMD[@]}"
        fi
    fi
}

# Loop through all clusters in the subcription and call setup_aks_config for
# each one.
setup_aks_configs_for_subscription() {
    local SUBSCRIPTION="$1"
    echo "# Setting up kubeconfigs clusters in subscription: $SUBSCRIPTION"
    az aks list --subscription "$SUBSCRIPTION" \
        --query "[].{name:name, resourceGroup:resourceGroup}" -o tsv | \
        while read -r CN RG; do

        if [[ -z "$CN" ]]; then
            continue
        fi

        setup_aks_config "$SUBSCRIPTION" "$CN" "$RG"
    done
}

setup_aks_configs_for_all_subscriptions() {
    az account list --query "[].name" -o tsv | while read -r SUB; do
        setup_aks_configs_for_subscription "$SUB"
    done
}

# Main script
if [[ -n "$SUBSCRIPTION" ]]; then
    if [[ -z "$CLUSTER_NAME" ]]; then
        if [[ -n "$RESOURCE_GROUP" ]]; then
            echo "You cannot specify a resource group without a cluster name."
            exit 1
        fi
        setup_aks_configs_for_subscription "$SUBSCRIPTION"
    else
        if [[ -z "$RESOURCE_GROUP" ]]; then
            RESOURCE_GROUP="$CLUSTER_NAME"
        fi
        setup_aks_config "$SUBSCRIPTION" "$CLUSTER_NAME" "$RESOURCE_GROUP"
    fi
else
    setup_aks_configs_for_all_subscriptions
fi
