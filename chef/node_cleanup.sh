#!/bin/bash
# Searches for stale nodes matching a given policy name and deletes the node
# and client. Prompts before each one just in case.
POLICY_NAME=frontend
NODES=$(knife status --hide-by-mins 60 "policy_name:$POLICY_NAME" -F json | \
    jq -r .[].name)

if [[ -z $NODES ]]; then
    echo "No nodes found that need cleaning up"
    exit 1
fi

for n in $NODES; do
    knife node show "$n" -a policy_group -a policy_name
    echo -n "Press ENTER to delete node and client (or ^C to exit)> "
    read -r
    knife node delete -y "$n"
    knife client delete -y "$n"
done
