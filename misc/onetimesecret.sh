#!/bin/bash
# Creates a one time secret using onetimesecret.com and displays
# the URL to the secret.
if [[ -n $1 ]]; then
    SECRET="$*"
else
    SECRET="<-" # Curl magic to read from stdin
fi

curl -s -F "secret=$SECRET" -F 'ttl=604800' \
    https://onetimesecret.com/api/v1/share | \
    jq -r '"https://onetimesecret.com/secret/\(.secret_key)"'
