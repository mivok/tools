#!/bin/bash
# This script gets the current SSID, BSSID, signal strength, frequency and
# channel that you are connected to. It also looks up the BSSID against a config
# file to identify a frienndly name for the acccess point you are connected to.
#
# Example config file format:
# # Comments and blank lines are allowed
# 00:11:22:33:44:55=My Home Network
# 00:66:77:88:99:AA=Office WiFi

CONFIG_FILE="$HOME/.config/wifi_info.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Get the current SSID, BSSID, signal strength, frequency and channel
# Using `iw` command to get the information
iw dev wlan0 link | awk '
    /^Connected to / { bssid=$3 }
    $1 == "SSID:" { ssid=$2 }
    $1 == "signal:" { signal=$2 }
    $1 == "freq:" { freq=$2 }
    END { print ssid, bssid, signal, freq }' | \
while read -r SSID BSSID SIGNAL FREQ; do
    # Check if the BSSID is in the config file
    FRIENDLY_NAME=$(grep -i "$BSSID" "$CONFIG_FILE" | awk -F'=' '{print $2}')
    if [ -z "$FRIENDLY_NAME" ]; then
        FRIENDLY_NAME="Unknown"
    fi

    # Print the information
    echo "     SSID: $SSID"
    echo "    BSSID: $BSSID"
    echo "   Signal: $SIGNAL dBm"
    echo "Frequency: $FREQ MHz"
    echo "  AP Name: $FRIENDLY_NAME"
done
