#!/bin/bash

usage() {
    echo "Usage: $0 [OPTIONS] COMMAND [ARGS]"
    echo
    echo "  -r -- Specify the AWS region to use"
    echo "  -p -- Specify an AWS profile to use"
    echo "  -l -- Loop through fzf commands until nothing is selected"
    echo "  -c -- Copy values to the clipboard instead of printing them"
    echo
    echo "Commands:"
    echo
    echo "  list [PATTERN] -- list parameters matching pattern"
    echo "  get [PATH]     -- get parameter at the given path"
    echo "  find [PATTERN] -- use fzf to find a parameter, then get its value"
    exit 254
}

list_params() {
    OPTS=()
    if [[ -n $1 ]]; then
        OPTS=(--parameter-filters "Key=Name,Option=Contains,Values=$1")
    fi
    aws ssm describe-parameters "${OPTS[@]}" | jq -r ".Parameters[].Name"
}

get_param() {
    if [[ -z $1 ]]; then
        usage
    fi

    if [[ -n "$VERBOSE" ]]; then
        FILTER='.Parameter | [.Name, .Value] | @tsv'
    else
        FILTER='.Parameter.Value'
    fi

    if [[ -n $USE_CLIPBOARD ]]; then
        aws ssm get-parameter --name "$1" --with-decryption | \
            jq -r "$FILTER" | tr -d '\n' | pbcopy
        echo "[Value has been copied to the clipboard]"
    else
        aws ssm get-parameter --name "$1" --with-decryption | jq -r "$FILTER"
    fi
}

find_param() {
    PARAMS="$(list_params "$@")"

    if [[ -z $PARAMS ]]; then
        echo "No parameters found. Exiting."
        exit 1
    fi

    while true; do
        PARAM="$(echo "$PARAMS" | fzf)"
        if [[ -n "$PARAM" ]]; then
            get_param "$PARAM"
        else
            if [[ -n "$LOOP" ]]; then
                # We normally loop, so an empty selection is normal and we
                # should exit cleanly.
                break
            else
                # We didn't have the loop option set, so print a message and
                # exit with an error code
                echo "No parameter selected. Exiting."
                exit 1
            fi
        fi
        if [[ -z "$LOOP" ]]; then
            break
        fi
        echo -n "Press Enter to continue..."
        read -r
    done
}

# Main script starts here
VERBOSE=
LOOP=
USE_CLIPBOARD=
while getopts ":clp:r:v" opt; do
    case $opt in
        c)  USE_CLIPBOARD=1
            ;;
        p)  export AWS_PROFILE="$OPTARG"
            ;;
        r)  export AWS_DEFAULT_REGION="$OPTARG"
            ;;
        l)  LOOP=1
            ;;
        v)  VERBOSE=1
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

ACTION="$1"
if [[ -z "$ACTION" ]]; then
    usage
fi
shift

case "$ACTION" in
    list)
        list_params "$@"
        ;;
    get)
        get_param "$@"
        ;;
    find)
        find_param "$@"
        ;;
    *)  echo "Invalid command -- '$ACTION'"
        usage
        ;;
esac
