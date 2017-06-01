#!/bin/bash
# Looks for semaphore arrays for which every semaphore in the array has a pid
# associated with it that no longer exists. It then spits out a list of ipcrm
# commands you can use to clean them up.
SETS=$(ipcs -s | tail -n +4 | awk '{print $2}')
for s in $SETS; do
    PIDS=$(ipcs -s -i $s | tail -n +9 | awk '{print $NF}')
    PID_FOUND=
    for p in $PIDS; do
        [[ -d /proc/$p ]] && PID_FOUND=1
    done
    if [[ -z $PID_FOUND ]]; then
        echo "ipcrm -s $s"
    fi
done
