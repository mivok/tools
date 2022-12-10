#!/bin/bash
# Generate a QR code from the contents of the clipboard and display it
# Useful for transferring data from a laptop to a phone or other device that can
# scan QR codes
xclip -o -selection clipboard | \
    qrencode -o - |
    feh -
