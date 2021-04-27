#!/bin/bash

PEERNAME=$1
ENDPOINT="YOURENDPOINT"
IPRANGE="10.10.10"
SERVERIP="254"
NETMASK="32"
IFACE="wg0"


# check if user is root
if (( $EUID != 0 )); then
	echo "Please run as root"
	exit
fi

# check if arg is set
if [ -z "$1" ]; then
	echo "No peer name specified"
	echo "Usage: $(basename $0) <peername>"
	exit
fi


# generate the keys
wg genkey > privatekey.tmp
cat privatekey.tmp | wg pubkey > pubkey.tmp


# read keys into variables
PRIVATEKEY=$(cat privatekey.tmp)
PUBLICKEY=$(cat pubkey.tmp)
SERVER_PUBLICKEY=$(cat server-publickey)


# read current IP suffix from file, increase it and echo new value back into tmp file
IP=$(cat ipcounter.tmp)
((IP++))
echo "$IP" > ipcounter.tmp

# Generate client and server configs
CONF_SERVER="
[Peer]
# $PEERNAME
PublicKey = $PUBLICKEY
AllowedIPs = $IPRANGE.$IP/$NETMASK"

CONF_CLIENT="[Interface]
Address = $IPRANGE.$IP/$NETMASK
PrivateKey = $PRIVATEKEY

[Peer]
PublicKey = $SERVER_PUBLICKEY
Endpoint = $ENDPOINT
AllowedIPs = $IPRANGE.$SERVERIP/$NETMASK
PersistentKeepalive = 25
"

# Write configs to server or client files
echo "$CONF_CLIENT" > "peers/$PEERNAME.conf"
echo "$CONF_SERVER" >> "/etc/wireguard/$IFACE.conf"

wg setconf $IFACE <(wg-quick strip $IFACE)

# remove tmp files
rm privatekey.tmp pubkey.tmp
