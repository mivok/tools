#!/bin/bash
# Creates a one time secret from stdin using onetimesecret.com and displays
# the URL to the secret.
curl -s -F 'secret=<-' -F 'ttl=604800' \
    https://onetimesecret.com/api/v1/share | \
    jq -r '"https://onetimesecret.com/secret/\(.secret_key)"'
