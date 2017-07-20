#!/bin/bash
URL="$1"

if [[ -z $URL ]]; then
    echo "Usage: $0 URL"
    echo "Convert webpage to markdown and copy to clipboard"
fi

curl -s -G "http://heckyesmarkdown.com/go/" \
    -d "read=1" \
    -d "preview=0" \
    -d "output=json" \
    -d "u=$URL" | \
    jq -r '"# \(.title)\n\n[Source](\(.url) \"Permalink to \(.title)\")\n\n\(.markdown)"' | \
    pbcopy
echo "Content of $URL copied to clipboard"
