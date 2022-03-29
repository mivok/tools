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
FORMAT_ARGS=(-subject -ext subjectAltName -issuer -dates)

while getopts ":aep:" opt; do
    case $opt in
        a)  FORMAT_ARGS=(-text)
            ;;
        e)  FORMAT_ARGS=(-dates)
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
echo | \
    openssl s_client -connect "$HOST:$PORT" 2>&1 | \
    openssl x509 -noout "${FORMAT_ARGS[@]}" | \
    perl -pe '
        # Convert "fooBar=" into "FooBar: "
        s/^(\S)([^= ]*)=/\u\1\2: /;
        # Remove X509v3 from the extension titles
        s/^X509v3 //;
    '
