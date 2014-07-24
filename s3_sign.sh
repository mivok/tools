#!/bin/bash
# Generates a temporary URL for s3 access downloads. Requires that you set the
# AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY variables
BUCKET="$1"
FILE="$2"
METHOD="GET"
EXPIRE="1440" # minutes
[[ -n $3 ]] && EXPIRE=$3

urlencode() {
    # From http://stackoverflow.com/questions/296536
    local string="$1"
    local strlen=${#string}
    local encoded=""

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            # I added % and = as things to not encode - % allows the filename
            # to be urlencoded itself if needed and = doesn't affect the
            # signature. This can be changed as needed if it causes problems.
            [-_.~a-zA-Z0-9%=] )
                o="${c}"
                ;;
            * )
                printf -v o '%%%02X' "'$c"
        esac
        encoded+="${o}"
    done
    echo "$encoded"
}

FILE=$(urlencode "$FILE")
EXPIRETS=$(( $(date +%s) + $EXPIRE * 60 ))
SIGNATURE=$(echo -en "$METHOD\n\n\n$EXPIRETS\n/$BUCKET/$FILE" | \
    openssl dgst -sha1 -binary -hmac "$AWS_SECRET_ACCESS_KEY" | \
    openssl base64)
SIGNATURE=$(urlencode "$SIGNATURE")
QUERY="AWSAccessKeyId=$AWS_ACCESS_KEY_ID&Expires=$EXPIRETS"
QUERY="$QUERY&Signature=$SIGNATURE"

echo "http://s3.amazonaws.com/$BUCKET/$FILE?$QUERY"
