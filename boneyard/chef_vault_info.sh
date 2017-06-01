#!/bin/bash
# Print out details of who/what a vault item is encrypted to. Requires jq.
usage() {
    echo "Usage: $0 [-a|-c|-s] VAULT ITEM"
    echo "Shows information on who a vault item is currently encrypted to"
    exit -1
}

FIELDS=()
while getopts ":acs" opt; do
    case $opt in
        a) FIELDS+=('admins') ;;
        c) FIELDS+=('clients') ;;
        s) FIELDS+=('search_query') ;;
        *) echo "Invalid option -- '$OPTARG'"
           usage
           ;;
    esac
done
shift $((OPTIND-1))
VAULT=$1
ITEM=$2
[[ -z $VAULT || -z $ITEM ]] && usage

FIELDSTR=$(printf ",%s" "${FIELDS[@]}")
FIELDSTR=${FIELDSTR:1}
if [[ -z $FIELDSTR ]]; then
    FIELDSTR="search_query"
fi

knife data bag show "$VAULT" "${ITEM}_keys" -f json | jq "{$FIELDSTR}"
