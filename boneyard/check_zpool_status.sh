#!/bin/bash
# Runs zpool status and alerts if anything isn't showing as ONLINE or if any
# of the error counts are greater than 0. Suitable for running with
# nagios/nrpe or sensu.

# Nagios exit codes
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

POOL=
STATE=
ERRORS=
OUTPUT=

while read -r LINE; do
    if [[ $LINE =~ pool:\ (.*) ]]; then
        POOL=${BASH_REMATCH[1]}
    elif [[ $LINE =~ state:\ (.*) ]]; then
        STATE=${BASH_REMATCH[1]}
    elif [[ $LINE =~ ([a-zA-Z0-9-]+)\ +([A-Z]+)\ +([0-9.]+[KMG]?)\ +([0-9.]+[KMG]?)\ +([0-9.]+[KMG]?) ]]; then
        VDEV=${BASH_REMATCH[1]}
        VDEV_STATE=${BASH_REMATCH[2]}
        VDEV_RERR=${BASH_REMATCH[3]}
        VDEV_WERR=${BASH_REMATCH[4]}
        VDEV_CERR=${BASH_REMATCH[5]}
        if [[ $VDEV_STATE != "ONLINE" ]]; then
            ERRORS="$ERRORS $VDEV:$VDEV_STATE"
        fi
        if [[ $VDEV_RERR != 0 ]]; then
            ERRORS="$ERRORS $VDEV:read:$VDEV_RERR"
        fi
        if [[ $VDEV_WERR != 0 ]]; then
            ERRORS="$ERRORS $VDEV:write:$VDEV_WERR"
        fi
        if [[ $VDEV_CERR != 0 ]]; then
            ERRORS="$ERRORS $VDEV:checksum:$VDEV_CERR"
        fi
    elif [[ $LINE =~ errors: ]]; then
        # The errors: line signifies the end of a pool's info
        if [[ -n $ERRORS || $STATE != "ONLINE" ]]; then
            OUTPUT="$OUTPUT $POOL: $STATE$ERRORS"
            ERRORS=
        fi
    fi
done < <(zpool status)

if [[ -n $OUTPUT ]]; then
    echo "ZPOOL CRITICAL:$OUTPUT"
    exit $CRITICAL
else
    echo "ZPOOL OK: no errors"
    exit $OK
fi
