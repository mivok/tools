#!/bin/bash
# Recovers a commit from github if you force pushed something bad. You need
# the SHA1 to recover.
#
# Setup instructions:
# - Go to https://github.com/settings/applications and create a personal
#   access token.
# - Store this in ~/.githubtoken (the entire content of the file should be the
#   token)
# - Identify the SHA1 of the commit you want to recover from github.
# - Run this command to create a new branch pointing to the SHA1 of the
#   commit. Note: this needs to be a full SHA1. An abbreviated SHA is
#   insufficient. If you only have a partial SHA1, go to:
#   https://github.com/<user>/<repo>/commit/<partial_sha1> and the full SHA1
#   will be shown on that page.
REPO=$1
SHA=$2
BRANCH=$3
TOKEN=$(cat $HOME/.githubtoken)
[[ -z $BRANCH ]] && BRANCH=D-commit
if [[ -z $REPO || -z $SHA ]]; then
    echo "Usage: $0 USER/REPO SHA [BRANCH]"
    echo
    echo "If a branch name isn't given, it defaults to D-commit"
    exit 1
fi

curl -u $TOKEN:x-oauth-basic -i -H "Accept: application/json" \
    -H "Content-Type: application/json" -X POST \
    -d '{
        "ref":"refs/heads/'$BRANCH'",
        "sha":"'$SHA'"}' \
        https://api.github.com/repos/$REPO/git/refs
