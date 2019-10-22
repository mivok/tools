#!/bin/bash
# Copyright (c) 2017 Mark Harrison
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# URL shortener using S3
#
# Setup:
#
# - Requirements - a domain used for shortening, hosted with route 53.
#
# - Create an S3 bucket with the name of your shortener domain
#   - Set the index document and error documents to index.html and error.html
#     respectively.
#   - You can shorten urls with the keys of 'index.html' and 'error.html' to
#     set where you want the base domain and any unknown URLs to go to.
# - Enable static web hosting for the S3 bucket
# - Note the hostname for the website hosting:
#       bucket.name.s3-website-us-east-1.amazonaws.com
# - In route 53, add an alias record for the shortener domain, and pick the S3
#   bucket from the list of available options.
#
# - Create ~/.aws/credentials if it doesn't already exist to store your AWS
#   credentials. This is the same format as used for the AWS CLI. If you don't
#   already use the AWS cli, it look like:
#
#       [default]
#       aws_access_key_id = AKIA...
#       aws_secret_access_key = ....
#
# - Create ~/.s3shorten:
#
#   BUCKET="yourdomain.com"
#   PROFILE="default"
#
# - Change the bucket to the name of your S3 bucket created before
# - If you used an alternative profile in your credentials file (i.e. you
#   added a section called '[myprofile]' to the aws credentials file,
#   then change the profile setting in ~/.s3shorten to match.

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
        --acl public-read \
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
