#!/bin/bash
# Converts a mac screencast (created with Command-Shift-5) in .mov format to
# an optimized gif.
#
# Requires ffmpeg and gifsicle (brew install ffmpeg gifsicle)
FILENAME="$1"
shift

if [[ -z $FILENAME ]]; then
    echo "Usage: $0 SCREENCAST_FILE"
    echo
    echo "Converts a .mov to an animated gif"
    echo
    exit 1
fi

if ! command -v ffmpeg > /dev/null || ! command -v gifsicle > /dev/null; then
    echo "This tool needs ffmpeg and gifsicle to be present."
    echo
    echo "Install them using 'brew install ffmpeg gifsicle'"
    exit 1
fi

ffmpeg -i "$FILENAME" -f gif -vf "scale=640:-1" -r 10 - | \
    gifsicle --optimize=3 > "${FILENAME/.mov/}.gif"
