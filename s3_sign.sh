#!/bin/bash
# Generates a temporary URL for s3 access downloads. Requires that you set the
# AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY variables
BUCKET="$1"
FILE="$2"
METHOD="GET"
EXPIRE="1440" # minutes

EXPIRETS=$(( $(date +%s) + $EXPIRE * 60 ))
SIGNATURE=$(echo -en "$METHOD\n\n\n$EXPIRETS\n/$BUCKET/$FILE" | \
    openssl dgst -sha1 -binary -hmac "$AWS_SECRET_ACCESS_KEY" | \
    openssl base64)
QUERY="AWSAccessKeyId=$AWS_ACCESS_KEY_ID&Expires=$EXPIRETS"
QUERY="$QUERY&Signature=$SIGNATURE"

echo "http://s3.amazonaws.com/$BUCKET/$FILE?$QUERY"
