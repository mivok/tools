#!/bin/bash
# Bumps a version number in a file whose contents are entirely a version
# number

# Defaults
TYPE="patch"
FILENAME="VERSION"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "    -f -- filename that contains the version (default: VERSION)"
    echo "    -t -- version field to bump (major, minor, patch)"
    exit 254
}

while getopts ":f:t:" opt; do
    case $opt in
        f)  FILENAME="$OPTARG"
            ;;
        t)  TYPE="$OPTARG"
            if [[ ! $TYPE =~ ^(major|minor|patch)$ ]]; then
                echo "Invalid type: $TYPE"
                usage
            fi
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
[[ -n "$1" ]] && usage

VERSION=$(<"$FILENAME")
if [[ $VERSION =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
    PATCH="${BASH_REMATCH[3]}"

    case "$TYPE" in
        major)
            ((MAJOR++)) ;;
        minor)
            ((MINOR++)) ;;
        patch)
            ((PATCH++)) ;;
    esac

    echo "$MAJOR.$MINOR.$PATCH" > "$FILENAME"
    echo "Bumped version: $VERSION -> $MAJOR.$MINOR.$PATCH"
else
    echo "Unable to find a version number. Exiting"
    exit 1
fi
