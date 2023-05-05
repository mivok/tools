#!/bin/bash
# Move terraform state for a series of resources from one location to another

usage() {
    echo "Usage: $0 [OPTIONS] SOURCE_DIR DEST_DIR ADDRESS [ADDRESS...]"
    echo
    echo "Move terraform state for multiple resources at once from one location"
    echo "to another."
    echo
    echo "SOURCE_DIR is the directory for the terraform root module you want"
    echo "    to move resources from."
    echo "DEST_DIR is the directory for the terraform root module you want"
    echo "    to move resources to."
    echo "ADDRESS is an address to the resource or module you wish to move."
    echo "    you can specify multiple addresses, and you can move entire"
    echo "    modules at once by specifying the address to just the module."
    echo
    echo "Options:"
    echo
    echo "   -d -- Add additional debug output"
}

# shellcheck disable=SC2120
confirm() {
    local PROMPT=$1
    [[ -z $PROMPT ]] && PROMPT="OK to continue?"
    local REPLY=
    while [[ ! $REPLY =~ ^[YyNn]$ ]]; do
        echo -n "$PROMPT (y/n) "
        read -r
    done
    # The result of this comparison is the return value of the function
    [[ $REPLY =~ ^[Yy]$ ]]
}

msg() {
    echo "=> $*"
}

debug() {
    [[ -n "$DEBUG" ]] && echo "=> DEBUG: $*"
}

cleanup() {
    # Remove temporary files. SCRIPT_TMPDIR is set later in the script
    if [[ -n "$SCRIPT_TMPDIR" ]]; then
        msg "Cleaning up temporary files"
        debug "Deleting $SCRIPT_TMPDIR"
        rm -rf "$SCRIPT_TMPDIR"
    fi
}

#
# Main script starts here
#
DEBUG=
while getopts ":d" opt; do
    case $opt in
        d)  DEBUG=1
            ;;
        :)  echo "Option missing required argument -- '$OPTARG'" 
            usage
            exit 254
            ;;
        *)  echo "Invalid option -- '$OPTARG'"
            usage
            exit 254
            ;;
    esac
done
shift $((OPTIND-1))

SOURCE_DIR="$1"
DEST_DIR="$2"
shift 2

if [[ -z "$SOURCE_DIR" || -z "$DEST_DIR" || "$#" -eq 0 ]]; then
    usage
    exit 254
fi

# Sanity checks before starting
debug "Verifying $SOURCE_DIR and $DEST_DIR exist"

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "$SOURCE_DIR doesn't exist. Exiting."
    exit 1
fi

if [[ ! -d "$DEST_DIR" ]]; then
    echo "$DEST_DIR doesn't exist. Exiting."
    exit 1
fi

debug "Creating temporary directory to hold intermediate files"
SCRIPT_TMPDIR="$(mktemp -d)"
debug "Temporary directory is $SCRIPT_TMPDIR"

msg "Running terraform init in source directory"
cd "$SOURCE_DIR" || exit 1
terraform init
cd - > /dev/null || exit 1

msg "Running terraform init in destination directory"
cd "$DEST_DIR" || exit 1
terraform init
cd - > /dev/null || exit 1

msg "Pulling source state file"
SOURCE_LOCAL_STATE="$SCRIPT_TMPDIR/source.tfstate"
cd "$SOURCE_DIR" || exit 1
terraform state pull > "$SOURCE_LOCAL_STATE" || {
    echo "Failed to pull source state file"
    exit 1
}
cp "$SCRIPT_TMPDIR/source.tfstate" "$SCRIPT_TMPDIR/source.tfstate.orig"
cd - > /dev/null || exit 1
debug "Local source state file is: $SOURCE_LOCAL_STATE"

msg "Pulling destination state file"
DEST_LOCAL_STATE="$SCRIPT_TMPDIR/dest.tfstate"
cd "$DEST_DIR" || exit 1
terraform state pull > "$DEST_LOCAL_STATE" || {
    echo "Failed to pull destination state file"
    exit 1
}
cp "$SCRIPT_TMPDIR/dest.tfstate" "$SCRIPT_TMPDIR/dest.tfstate.orig"
cd - > /dev/null || exit 1
debug "Local destination state file is: $SOURCE_LOCAL_STATE"

msg "Moving resources"
for ADDRESS in "$@"; do
    echo "$ADDRESS"
    terraform state mv \
        -state="$SOURCE_LOCAL_STATE" \
        -state-out="$DEST_LOCAL_STATE" \
        "$ADDRESS" "$ADDRESS"
done

if confirm "View a diff of the modified states?"; then
    {
        diff -u "$SCRIPT_TMPDIR/source.tfstate.orig" \
            "$SCRIPT_TMPDIR/source.tfstate"
        diff -u "$SCRIPT_TMPDIR/dest.tfstate.orig" \
            "$SCRIPT_TMPDIR/dest.tfstate"
    } | less
fi

confirm "Do you wish to upload the modified state files?" || {
    cleanup
    echo "Exiting."
    exit 1
}

msg "Pushing source state"
cd "$SOURCE_DIR" || exit 1
terraform state push "$SOURCE_LOCAL_STATE" || {
    echo "Failed to push local state."
    # Note: don't clean up here because we might want to manually fix the
    # problem and upload the modified state
    echo "Local state files are in $SCRIPT_TMPDIR"
    exit 1
}
cd - > /dev/null || exit 1

msg "Pushing destination state"
cd "$DEST_DIR" || exit 1
terraform state push "$DEST_LOCAL_STATE" || {
    echo "Failed to push local state"
    # Note: don't clean up here because we might want to manually fix the
    # problem and upload the modified state
    echo "Local state files are in $SCRIPT_TMPDIR"
    exit 1
}
cd - > /dev/null || exit 1

cleanup
msg "Done"
