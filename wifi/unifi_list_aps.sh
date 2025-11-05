#!/bin/bash
# This script lists all BSSIDs on all Access Points (APs) managed by a UniFi
# Controller. The output format is "BSSID=AP_NAME ESSID", which is suitable for
# use with the wifi_info.sh script.
#
# It requires 'curl' and 'jq' to be installed on the system.
# Usage: ./unifi_list_aps.sh <controller_url> <username> <password> <site_id>
# Example: ./unifi_list_aps.sh https://unifi-controller.local admin password
# default site_id is 'default'

if [[ "$#" -lt 3 ]]; then
    echo "Usage: $0 <controller_url> <username> <password> [site_id]"
    exit 1
fi

CONTROLLER_URL="$1"
USERNAME="$2"
PASSWORD="$3"
SITE_ID="${4:-default}"

COOKIES_FILE=$(mktemp)
trap 'rm -f "$COOKIES_FILE"' EXIT

# Login
curl -s -c "$COOKIES_FILE" -X POST "$CONTROLLER_URL/api/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" | \
    jq -e '.meta.rc == "ok"' >/dev/null || { echo "Login failed"; exit 1; }

# List APs
curl -s -b "$COOKIES_FILE" "$CONTROLLER_URL/api/s/$SITE_ID/stat/device" |
    jq -r '.data[] | select(.type == "uap") | .name as $ap_name | 
    .vap_table[] | "\(.bssid | ascii_upcase)=\($ap_name) \(.essid)"'
