#!/bin/bash
# SSH to all azure instances in a VMSS in parallel
#
# Differences from the AWS version:
#
# - All regions are shown at once. You don't have to specify a specific
# region.
# - You don't specify the subscription on the command line. Use az account set
# instead to switch subscriptions. This may change in future if we find we
# need to do so.
#
# Requirements:
#
# brew install fzf azure-cli jq
#
# You should also have your ssh configuration set up to automatically hop
# through the appropriate bastion. This command just connects to a specific
# private IP address. See the wiki for information on this.

DEPENDENCIES=(fzf az jq)
MISSING_DEPS=()
for DEP in "${DEPENDENCIES[@]}"; do
    if ! command -v "$DEP" >/dev/null 2>&1; then
        MISSING_DEPS+=("$DEP")
    fi
done

if [[ "${#MISSING_DEPS[@]}" -gt 0 ]]; then
    echo "This script needs the following to be installed: ${MISSING_DEPS[*]}"
    echo "Please install them (e.g. using 'brew install TOOLNAME')."
    exit 254
fi

PATTERN="$1"
shift

if [[ -z "$PATTERN" ]]; then
    echo "Usage: $0 PATTERN COMMAND..."
    echo
    echo "SSH to all instances in a VMSS in parallel using pssh"
    echo
    echo "Example:"
    echo
    echo "$0 pythia date"
    exit 1
fi

VMSS=$(az vmss list | jq -r '.[].name' | fzf -0 -1 -q "$PATTERN")

if [[ -z "$VMSS" ]]; then
    echo "No VMSS was selected (or no match found), exiting..."
    exit 1
fi

echo "=> Selected $VMSS"
# You need the resource group as well as the vmss name to refer to it
RESOURCEGROUP=$(az vmss list | jq -r '.[] |
    select(.name == "'"$VMSS"'") | .resourceGroup')
HOSTS=$(az vmss nic list -g "$RESOURCEGROUP" --vmss-name "$VMSS" | \
    jq -r '.[].ipConfigurations[].privateIpAddress')

pssh \
    -O 'StrictHostKeyChecking no' \
    --host "$HOSTS" \
    --par 5\
    --timeout 3600 \
    --inline \
    "$@"
