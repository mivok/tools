#!/bin/bash
# Search for instances matching given criteria
EXACTMATCH=
REVERSE_IP_DISPLAY=
FILTERKEY=

usage() {
    echo "Usage: $0 [-r REGION] [-p PROFILE] PATTERN"
    echo
    echo "Easily search for aws instances"
    echo
    echo "  -r REGION    -- Specify AWS region (Default: $AWS_DEFAULT_REGION)"
    echo "  -p PROFILE   -- Specify credentials profile (Default: $AWS_PROFILE)"
    echo "  -f FILTERKEY -- What to filter on (Default: auto)"
    echo "  -i           -- Display Public IP Address (Default: private)"
    echo "  -x           -- Only return exact matches (Default: partial)"
    echo
    echo "Run 'aws ec2 describe instances help' to view available filter keys"
    echo
    echo "Examples: tag:Name, tag:Environment, ip-address,"
    echo "private-ip-address, availability-zone"
    echo
    echo "'auto' will detect IP addresses (rfc1918 for private IPs) or instance"
    echo "IDs beginning with 'i-', and will search the name tag otherwise"
    echo
    echo "When searching by public IP, the public IP will be displayed by"
    echo "default, and the meaning of -i is reversed."
}

while getopts ":f:hip:r:x" opt; do
    case $opt in
        f)  FILTERKEY="$OPTARG"
            ;;
        p)  export AWS_PROFILE="$OPTARG"
            ;;
        i)  REVERSE_IP_DISPLAY=1
            ;;
        r)  export AWS_DEFAULT_REGION="$OPTARG"
            ;;
        x)  EXACTMATCH=1
            ;;
        h)  usage
            exit
            ;;
        *)  echo "Invalid option -- '$OPTARG'"
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

PATTERN="$1"

[[ -z $1 ]] && usage

# Decide what to search for based on input heuristic
if [[ -z $FILTERKEY || $FILTERKEY == "auto" ]]; then
    FILTERKEY="tag:Name"

    if [[ $PATTERN =~ ^i- ]]; then
        FILTERKEY="instance-id"
    elif [[ $PATTERN =~ ^(172\.(1[6-9]|2[0-9]|3[0-1])\.|10\.|192\.168\.) ]]; then
        FILTERKEY="private-ip-address"
    elif [[ $PATTERN =~ [0-9.] ]]; then
        FILTERKEY="ip-address"
    fi
fi

if [[ -z $EXACTMATCH ]]; then
    PATTERN="*$PATTERN*"
fi

IPATTR="PrivateIpAddress"
if [[ (-n $REVERSE_IP_DISPLAY && $FILTERKEY != "ip-address") ||
      (-z $REVERSE_IP_DISPLAY && $FILTERKEY == "ip-address") ]]; then
    IPATTR="PublicIpAddress"
fi

aws ec2 describe-instances \
    --filters "Name=$FILTERKEY,Values=$PATTERN" | \
    jq -r '[
        .Reservations[].Instances[] |
            [
                .InstanceId,
                .'"$IPATTR"',
                [.Tags[] | select(.Key == "Name") | .Value][0]
            ]
        ] | sort_by(.[2]) | .[] | @tsv'
