#!/bin/bash
# Checks to see if a given tls certificate matches the given key file
usage() {
    echo "Usage: $0 CERT_FILE KEY_FILE"
    echo
    echo "Compares a TLS certificate with a key and prints out if the"
    echo "certificate and key match"
    exit 254
}

CERT_FILE="$1"
KEY_FILE="$2"

[[ -z "$CERT_FILE" || -z "$KEY_FILE" ]] && usage

CERT_MODULUS="$(openssl x509 -in "$CERT_FILE" -noout -modulus)"
KEY_MODULUS="$(openssl rsa -in "$KEY_FILE" -noout -modulus)"

if [[ -z "$CERT_MODULUS" ]]; then
    echo "Problem getting modulus from certificate file. Exiting."
    exit 1
fi

if [[ -z "$KEY_MODULUS" ]]; then
    echo "Problem getting modulus from key file. Exiting."
    exit 1
fi

if [[ "$CERT_MODULUS" == "$KEY_MODULUS" ]]; then
    echo "$CERT_FILE and $KEY_FILE match"
else
    echo "$CERT_FILE and $KEY_FILE do NOT match"
    exit 1
fi

