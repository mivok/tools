#!/bin/bash
# Simple filter for curl that will follow a chain of redirects, printing them
# out for you, before also printing the final response code.
#
# Example:
#
# $ check_redirect.sh git.io/sqp
# 302 https://github.com/mivok/squirrelpouch/wiki/Home
# 301 https://github.com/mivok/squirrelpouch/wiki
# Response: 200

curl -o /dev/null -L -v "$@" 2>&1 | awk '
    /^\* Connected to .* \([0-9.]+\)/ { print "IP: " $5 }
    /^< HTTP\/[0-9.]+ 3/ { printf "%s ", $3 }
    /^< HTTP\/[0-9.]+ [^3]/ { print "Response: " $3 }
    /^< [Ll]ocation:/ { print $3 }
'
