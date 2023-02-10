#!/bin/bash

usage() {
    echo "Usage: $0 [OPTIONS] HOSTNAME"
    echo "Prints out TLS certificate information for a host"
    echo
    echo "Options:"
    echo "  -a -- Print out all certificate information"
    echo "  -e -- Print out certificate start/end dates"
    echo "  -p -- Port to connect to"
    exit 254
}

PORT=443
# Information to print out by default
FORMAT_ARGS=(-subject -issuer -dates)
GET_SANS=1

while getopts ":aep:" opt; do
    case $opt in
        a)  FORMAT_ARGS=(-text)
            GET_SANS=
            ;;
        e)  FORMAT_ARGS=(-dates)
            GET_SANS=
            ;;
        p)  PORT="$OPTARG"
            ;;
        :)  echo "Option missing required argument -- '$OPTARG'"
            usage
            ;;
        *)  echo "Invalid option -- '$OPTARG'"
            usage
            ;;
    esac
done
shift $((OPTIND-1))

HOST="$1"
if [[ -z "$HOST" ]]; then
    usage
fi

echo "==> $HOST"

CERT_OUT="$(echo | openssl s_client -connect "$HOST:$PORT" 2>/dev/null)"

echo "$CERT_OUT" | \
    openssl x509 -noout "${FORMAT_ARGS[@]}" | \
    perl -pe '
        # Convert "fooBar=" into "FooBar: "
        s/^(\S)([^= ]*)=/\u\1\2: /;
    '

if [[ -n "$GET_SANS" ]]; then
    # Manually parse out subjectaltname from text output because the version of
    # openssl/libressl with macs doesn't support -ext subjectAltName
    echo "Subject Alternative Names: "
    echo "$CERT_OUT" | \
        openssl x509 -noout -text | \
        grep -A1 'Subject Alternative Name:' | \
        grep 'DNS:' | \
        sed -e 's/DNS://g' -e 's/^ */    /' -e 's/, /\n    /g'
fi
