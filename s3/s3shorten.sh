#!/bin/bash
# Config file:
# BUCKET="bucketname"
# PROFILE="profile"

load_config() {
    CONFIG_FILE="$HOME/.s3shorten"

    if [[ -f $CONFIG_FILE ]]; then
        source $CONFIG_FILE
    else
        echo "No config file found, please create $CONFIG_FILE first"
        exit 1
    fi
}

usage() {
    echo "Usage:"
    echo "  $0 URL [KEY] -- Shorten URL"
    echo "  $0 -r KEY    -- Remove shortened URL"
    echo "  $0 -l        -- List shortened URLs"
    exit -1
}

list_links() {
    # This doesn't support spaces yet
    KEYS=$(aws --profile "$PROFILE" s3api list-objects --bucket "$BUCKET" | \
        jq -r .Contents[].Key)
    for k in $KEYS; do
        echo -n "$k => "
        aws --profile "$PROFILE" s3api head-object --bucket "$BUCKET" \
            --key "$k" | \
            jq -r .WebsiteRedirectLocation
    done
}

delete_link() {
    echo "Deleting: $1"
    aws --profile "$PROFILE" s3 rm "s3://$BUCKET/$1"
}

create_link() {
    echo "Creating short link $2 for $1"
    aws --profile "$PROFILE" s3api put-object --bucket "$BUCKET" --key "$2" \
        --website-redirect-location "$1"
}


## Main script
load_config

ACTION="create"
KEY=""
while getopts ":r:l" opt; do
    case $opt in
        r)  ACTION="delete"
            KEY="$OPTARG"
            ;;
        l)  ACTION="list"
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

case $ACTION in
    create)
        [[ -z $1 || -z $2 ]] && usage
        create_link "$1" "$2"
        ;;
    delete)
        delete_link "$KEY"
        ;;
    list)
        list_links
        ;;
esac
