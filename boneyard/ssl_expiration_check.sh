#!/bin/bash
# Quick script to print out expiration dates of SSL certificates for websites
#
# Usage:
# ./ssl_expiration_check.sh www.example.com www.example2.com www.example3.com

for h in "$@"; do
    echo -n "$h: "
    echo | openssl s_client -connect "$h":443 -servername "$h" 2>&1 | \
        openssl x509 -noout -dates | grep notAfter | awk -F= '{print $2}'
done
