#!/bin/bash
# Restore script for the vivaldi web browser (companion to backup_vivaldi.sh)
SOURCE="$HOME/Dropbox/backups/vivaldi"
DEST="$HOME/Library/Application Support/Vivaldi/Default"
cp -v "$SOURCE/*" "$DEST/"
