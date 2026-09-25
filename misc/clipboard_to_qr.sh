#!/bin/bash
# Generate a QR code from the contents of the clipboard and display it
# Useful for transferring data from a laptop to a phone or other device that can
# scan QR codes

if command -v wl-paste &> /dev/null && [[ -n "$WAYLAND_DISPLAY" ]]; then
    CLIPBOARD_COMMAND=(wl-paste)
elif command -v pbpaste &> /dev/null && [[ "$(uname)" == "Darwin" ]]; then
    CLIPBOARD_COMMAND=(pbpaste)
elif command -v xclip &> /dev/null && [[ -n "$DISPLAY" ]]; then
    CLIPBOARD_COMMAND=(xclip -o -selection clipboard)
elif command -v xsel &> /dev/null && [[ -n "$DISPLAY" ]]; then
    CLIPBOARD_COMMAND=(xsel --clipboard --output)
else
    echo "No suitable clipboard tool found."
    echo "Please install xclip, xsel, wl-paste, or pbpaste."
    exit 1
fi

# Specify the qrencode command here, but it can be overridden as needed
QRENCODE_COMMAND=(qrencode -t SVG -o -)

# Choose an appropriate image viewer
if command -v feh &> /dev/null; then
    VIEWER_COMMAND=(feh -Z -F -x -q -)
else
    VIEWER_COMMAND=(cat)
    QRENCODE_COMMAND=(qrencode -t ANSI -o -)
fi

"${CLIPBOARD_COMMAND[@]}" |
    "${QRENCODE_COMMAND[@]}" |
    "${VIEWER_COMMAND[@]}"
