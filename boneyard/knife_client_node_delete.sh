#!/bin/bash
# Delete a client and node at the same time
knife client delete -y "$@"
knife node delete -y "$@"
