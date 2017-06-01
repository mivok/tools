#!/bin/bash
# Backup script for the vivaldi web browser

DEST="$HOME/Dropbox/backups/vivaldi"
SOURCE="$HOME/Library/Application Support/Vivaldi/Default"
# Files to back up - see https://help.vivaldi.com/article/full-reset-of-vivaldi/
# for an explanation of what the various files are and add more as needed.
FILES=("$SOURCE"/{Preferences,Bookmarks,Notes})

mkdir -p "$DEST"
cp -v "${FILES[@]}" "$DEST"
