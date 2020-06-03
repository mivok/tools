#!/bin/bash
# List all resources in the current terraform state, filter then through fzf,
# and show the state for the selected resource.
RESOURCE=$(terrraform state list | fzf -q "$1" -1 -0)
if [[ -n "$RESOURCE" ]]; then
    terraform state show "$RESOURCE"
else
    echo "No resource selected. Exiting."
fi
