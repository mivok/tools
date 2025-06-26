#!/bin/bash

usage() {
    echo "Usage: $0 [OPTIONS] HOSTNAME|FILENAME"
    echo "Prints out TLS certificate information for a host or certificate file"
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

HOST_OR_FILE="$1"
if [[ -z "$HOST_OR_FILE" ]]; then
    usage
fi

echo "==> $HOST_OR_FILE"
if [[ -e "$HOST_OR_FILE" || "$HOST_OR_FILE" =~ .*\.(pem|crt) ]]; then
    # We have a file
    CERT_OUT="$(cat "$HOST_OR_FILE")"
else
    # We have a hostname
    CERT_OUT="$(echo | openssl s_client -servername "$HOST_OR_FILE" \
        -connect "$HOST_OR_FILE:$PORT" 2>/dev/null)"
fi

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
