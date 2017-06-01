#!/bin/bash
# Quickly adds a single host to a vault item without messing up the saved
# query. This is for when you have a new machine that hasn't completed a chef
# run yet and so doesn't match the saved query, and is a workaround for
# functionality not in chef-vault at the time of writing. It probably
# should be implemented in chef-vault directly at some point.
VAULT=$1
ITEM=$2
NEW_HOST=$3

if [[ -z $VAULT || -z $ITEM || -z $NEW_HOST ]]; then
    echo "Usage: $0 [vault] [item] [nodename]"
    echo "Adds a single client to the list of clients a vault is encrypted to"
    exit -1
fi

ORIG_QUERY=$(knife data bag show "$VAULT" "${ITEM}_keys" | grep search_query |
    awk '{print $2}')
echo "Original query: '$ORIG_QUERY'"
if [[ -z $ORIG_QUERY ]]; then
    echo "ERROR: no original query. Exiting."
    exit 1
fi
echo "Setting new query to: 'name:$NEW_HOST'"
knife vault update "$VAULT" "$ITEM" -S "name:$NEW_HOST"
echo "Resetting query back to '$ORIG_QUERY'"
knife vault update "$VAULT" "$ITEM" -S "$ORIG_QUERY"
echo -n "Verifying... "
NEW_QUERY=$(knife data bag show "$VAULT" "${ITEM}_keys" | grep search_query |
    awk '{print $2}')
if [[ "$ORIG_QUERY" == "$NEW_QUERY" ]]; then
    echo "Success"
else
    echo "ERROR: Query not reset successfully. Query is currently: '$NEW_QUERY'"
    exit 1
fi
