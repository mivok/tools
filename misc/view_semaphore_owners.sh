#!/bin/bash
# Shows the name of the process associated with every semaphore on the system,
# grouped by semaphore array.
SETS=$(ipcs -s | tail -n +4 | awk '{print $2}')
for s in $SETS; do
    echo "# $s"
    PIDS=$(ipcs -s -i $s | tail -n +9 | awk '{print $NF}')
    for p in $PIDS; do
        if [[ -f /proc/$p/comm ]]; then
            echo -n "$p "
            cat /proc/$p/comm
        else
            echo $p
        fi
    done
done
