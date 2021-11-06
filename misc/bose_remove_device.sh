#!/bin/bash
# Removes a paired device from bose headphones
# Requiremes: bluez-utils based-connect (AUR) fzf
DEVICE_ID=$(bluetoothctl devices | grep -i bose | awk '{print $2}')

if [[ -z "$DEVICE_ID" ]]; then
    echo "Unable to find bose device"
    echo "Connected devices:"
    bluetoothctl devices
    exit 1
fi

REMOVE_ID=$(based-connect -a "$DEVICE_ID" | tail +2 | fzf | cut -c 3-19)

echo "Removing device ID: $REMOVE_ID"
based-connect --remove-device="$REMOVE_ID" "$DEVICE_ID"

sleep 1
echo "New device list:"
based-connect -a "$DEVICE_ID"
