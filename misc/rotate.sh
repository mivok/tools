#!/bin/bash
# Rotate FILENAME to FILENAME.1, FILENAME.2 and so on
if [[ -z $1 ]]; then
    echo "Usage: $1 [filename]"
    echo "Rotates files"
    exit 1
fi

COPIES=5

for ((i=COPIES-1; i>0; i--)); do
    if [[ -f ${1}.$i ]]; then
        mv "${1}.$i" "${1}.$((i+1))"
    fi
done
mv "${1}" "${1}.1"
