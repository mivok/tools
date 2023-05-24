#!/bin/bash
# Search for instances matching given criteria
#
# # Search by instance name
# $ aws_instance_search.sh example
# i-0123456789abcdef0    172.31.1.43    example-acceptance
# i-0123456789abcdef1    172.31.0.11    example-acceptance
# i-0123456789abcdef2    172.31.1.24    example-production
# i-0123456789abcdef3    172.31.0.62    example-production
#
# # Search by private IP
# $ aws_instance_search.sh 172.31.1.4
# i-a123456789abcdef0    172.31.1.4     otherserver-production
# i-0123456789abcdef0    172.31.1.43    example-acceptance
#
# # -x means only return exact matches
# $ aws_instance_search.sh -x 172.31.1.4
# i-a123456789abcdef0    172.31.1.4     otherserver-production
#
# # -i means show the public IP address
# $ aws_instance_search.sh -i -x 172.31.1.4
# i-a123456789abcdef0    33.33.33.123   otherserver-production
#
# # Search by public IP (non-rfc1918 addresses search public IP field instead)
# $ aws_instance_search.sh 33.33.33.123
# i-a123456789abcdef0    33.33.33.123   otherserver-production
#
# # Search by (partial) instance ID
# $ aws_instance_search.sh i-a1234
# i-a123456789abcdef0    172.31.1.4     otherserver-production
#
# # Search by custom filter key
# $ aws_instance_search.sh -f X-Environment testing
# i-0123456789abcdef9    172.31.3.4     myserver-testing

EXACTMATCH=
REVERSE_IP_DISPLAY=
FILTERKEY=
ALL_INSTANCES=

usage() {
    echo "Usage: $0 [-r REGION] [-p PROFILE] PATTERN"
    echo
    echo "Easily search for aws instances"
    echo
    echo "  -r REGION    -- Specify AWS region (Default: $AWS_DEFAULT_REGION)"
    echo "  -p PROFILE   -- Specify credentials profile (Default: $AWS_PROFILE)"
    echo "  -f FILTERKEY -- What to filter on (Default: auto)"
    echo "  -a           -- Search all instances (Default: running instances)"
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

while getopts ":af:hip:r:x" opt; do
    case $opt in
        a)  ALL_INSTANCES=1
            ;;
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

if [[ -z $1 ]]; then
    usage
    exit 1
fi

# Decide what to search for based on input heuristic
if [[ -z $FILTERKEY || $FILTERKEY == "auto" ]]; then
    FILTERKEY="tag:Name"

    if [[ $PATTERN =~ ^i- ]]; then
        FILTERKEY="instance-id"
    elif [[ $PATTERN =~ ^(172\.(1[6-9]|2[0-9]|3[0-1])\.|10\.|192\.168\.) ]]; then
        FILTERKEY="private-ip-address"
    elif [[ $PATTERN =~ ^[0-9.]$ ]]; then
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

FILTERS=(
    "Name=$FILTERKEY,Values=$PATTERN"
)

if [[ "$ALL_INSTANCES" != "1" ]]; then
    FILTERS=("${FILTERS[@]}" "Name=instance-state-name,Values=running")
fi
aws ec2 describe-instances \
    --filters "${FILTERS[@]}" | \
    jq -r '[
        .Reservations[].Instances[] |
            [
                .InstanceId,
                .'"$IPATTR"',
                [.Tags // [] | .[] | select(.Key == "Name") | .Value][0]
            ]
        ] | sort_by(.[2]) | .[] | @tsv'
