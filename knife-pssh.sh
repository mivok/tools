#!/bin/bash
# Runs commands on many hosts at once using pssh, and using knife search to
# get a list of hosts to connect to.
# Requires knife, pssh and jq

if [[ -z $1 ]]; then
    echo "Usage: $0 SEARCH_TERM COMMAND"
    echo "Run a command on many hosts. Like knife ssh but using pssh instead"
    exit 1
fi

HOSTS=$(
    knife search node -a ipaddress "$1" -F json | \
        jq -r '.rows[] | to_entries[] | .value.ipaddress'
)
shift

if [[ -z $HOSTS ]]; then
    echo "No results returned from search"
    exit 1
fi

pssh \
    -O 'StrictHostKeyChecking no' \
    --host "$HOSTS" \
    --par 5\
    --inline \
    "$@"
