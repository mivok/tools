#!/bin/bash
# Manually install xtern-ghostty termtype on a remote server

USE_SUDO=
while [[ "$1" == --* ]]; do
    case "$1" in
        --sudo)
            USE_SUDO=1
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

if [[ -z "$1" ]]; then
    echo "Usage: fix_ghosty_ssh [--sudo] HOSTNAME"
    echo "manually installs the xterm-ghostty termtype on a remote server"
    echo
    echo "Options:"
    echo "  --sudo    Also install the entry to root via sudo"
    exit
fi

echo "Installing xterm-ghostty terminfo on $1"
infocmp -x xterm-ghostty | ssh "$1" -- tic -x -

if [[ -n "$USE_SUDO" ]]; then
    echo "Installing xterm-ghostty terminfo on $1 as root"
    infocmp -x xterm-ghostty | ssh "$1" -- sudo tic -x -
fi

