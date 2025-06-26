#!/bin/bash
# Displays AD groups for a given user in azure.
# Usage: ./ad_groups.sh <username>

USERNAME=$1
if [[ -z "$USERNAME" ]]; then
    echo "Usage: $0 <username>"
    exit 1
fi

# If the username isn't an email, add the tenant default domain to the end
if [[ ! "$USERNAME" =~ @ ]]; then
    TENANT_DOMAIN=$(az account show --query tenantDefaultDomain -o tsv)
    USERNAME="$USERNAME@$TENANT_DOMAIN"
fi

az ad user get-member-groups --id "$USERNAME" \
    --security-enabled-only false --output table | tail -n +3 | sort
