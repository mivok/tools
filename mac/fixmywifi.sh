#!/bin/bash
AIRPORT="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
SSID=$($AIRPORT -I | awk '/ SSID:/ { print $2 }')
AUTH=$($AIRPORT -I | awk '/link auth:/ { print $3 }')
if [[ -z $1 && $AUTH != "open" ]]; then
    echo "Usage: $0 PASSWORD"
    echo "Password is required because you are connected to a non-open wifi"
    exit 1
fi
echo "Reconnecting to: $SSID"
networksetup -setairportnetwork en0 "$SSID" "$1"
echo "Done"
