#!/bin/bash
# Generates a wireguard configuration file as well as commands to add the
# client to a wireguard server running Edgeos
# (https://github.com/Lochnair/vyatta-wireguard)

# Config file format
# SERVER="server.example.com:51280"
# SERVER_PUBLIC_KEY="..."
# ALLOWED_IPS="192.168.33.1/32,192.168.1.0/24"
# PORT="51280"

CONFIGFILE="$HOME/.wireguard_config.sh"

NAME="$1"
IP="$2"

if [[ -e "$CONFIGFILE" ]]; then
    # shellcheck disable=SC1090
    . "$CONFIGFILE"
else
    echo "Configuration file $CONFIGFILE doesn't exist. Please make it first"
    exit 1
fi

if ! command -v wg >/dev/null; then
    echo "The wireguard tools aren't installed, please install them first"
    exit 1
fi

if [[ -z "$NAME" || -z "$IP" ]]; then
    echo "Usage: $0 CLIENT_NAME CLIENT_IP_ADDRESS"
    echo
    echo "Generate a wireguard configuration file for a new client"
    echo
    echo "CLIENT_NAME: A friendly name for the client added to comments"
    echo "CLIENT_IP_ADDRESS: The IP to assign to the client"
    exit 1
fi

CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)

echo "=> Client configuration"
cat <<EOF
# $NAME
[Interface]
Address = $IP
ListenPort = $PORT
PrivateKey = $CLIENT_PRIVATE_KEY

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
EndPoint = $SERVER
AllowedIps = $ALLOWED_IPS
PersistentKeepAlive = 25
EOF

echo
echo "=> Edgeos commands"
cat <<EOF
set interfaces wireguard wg0 peer $CLIENT_PUBLIC_KEY
set interfaces wireguard wg0 peer $CLIENT_PUBLIC_KEY allowed-ips $IP/32
comment interfaces wireguard wg0 peer $CLIENT_PUBLIC_KEY '$NAME'
EOF
