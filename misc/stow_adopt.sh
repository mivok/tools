#!/bin/bash
# Adopt a file with GNU stow
#
# This script moves a real file into the appropriate location inside a GNU stow
# managed directory, and then re-runs stow to create the symlink again. Useful
# for moving a file inside your dotfiles repo.
SOURCE="$1"
PKG="$2"

if [[ -z "$SOURCE" || -z "$PKG" ]]; then
    echo "Usage: $0 SOURCE_FILE PKG"
    echo
    echo "Adopts a file that isn't already there into a repo managed by gnu stow"
    echo
    echo "SOURCE_FILE should point to the file to adopt"
    echo "PKG should point to a directory inside the current directory"
    exit 1
fi

ABSOLUTE_SOURCE="$(cd "$(dirname "$SOURCE")" && pwd)/$(basename "$SOURCE")"
DEST_DIR="$(dirname ${PKG}/${ABSOLUTE_SOURCE#"$HOME"/})"

# Make sure the destination directory exists
echo "=> Making directory $DEST_DIR"
mkdir -p "$DEST_DIR"
echo "=> Moving $SOURCE to $DEST_DIR"
mv "$SOURCE" "$DEST_DIR"
echo "=> Rerunning stow on $PKG"
stow -v "$PKG"
