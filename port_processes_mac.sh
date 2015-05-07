#!/bin/bash
# Prints out listening ports and their associated processes using lsof
if [[ -z $1 || $1 == "-t" ]]; then
    # TCP
    sudo lsof -n -P -i4TCP | \
        awk '$NF == "(LISTEN)" {
            printf "%9s %5s %8s %4s %20s\n", $1, $2, $3, $8, $9
        }'
elif [[ $1 == "-u" ]]; then
    # UDP
    sudo lsof -n -P -i4UDP | \
        awk '$NF != "*:*" && $NF !~ /->/ && $1 != "COMMAND" {
            printf "%9s %5s %8s %4s %20s\n", $1, $2, $3, $8, $9
        }'
else
    echo "Usage: $0 [-t|-u]"
    exit 1
fi
