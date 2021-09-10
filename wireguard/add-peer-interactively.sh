#!/bin/bash

ENDPOINT="YOURENDPOINT"
NETMASK="32"
WGDIR="/etc/wireguard"

# COLOR CODES
GREEN='\033[0;32m'
NC='\033[0m' # No Color
BOLD='\033[1m'

OKP="[  ${GREEN}OK${NC}  ]"


# check if user is root
if (( $EUID != 0 )); then
	echo "Please run as root"
	exit
fi

#for i in $(ls $WGDIR); do
#	echo $i | grep .conf

# WGINTERFACES="$(ls $WGDIR | grep .conf | rev | cut -c6- | rev)"
WGINTERFACES=($(wg show interfaces))
IFACENUM=${#WGINTERFACES[@]}

while [ $IFACENUM -ge ${#WGINTERFACES[@]} ] || [ $IFACENUM -lt 0 ]
do
	echo "Active Wireguard interfaces:"
	for (( i=0; i<${#WGINTERFACES[@]}; i++ ))
	do
    	echo "[$i] ${WGINTERFACES[$i]}"
	done
	read -p "Wireguard interface to modify? " IFACENUM
done
echo -e "$OKP Selected interface: ${BOLD}${WGINTERFACES[$IFACENUM]}${NC}"
IFACE=${WGINTERFACES[$IFACENUM]}

# Read in endpoint port and address
NETDEVS=($(ls -d /sys/class/net/*/device | cut -d/ -f5))
POSSIBLEENDPOINTS=($(hostname -f))
for (( i=0; i<${#NETDEVS[@]}; i++ ))
do
	POSSIBLEENDPOINTS+=($(ip -o -4 addr list ${NETDEVS[$i]} | awk '{print $4}' | cut -f1 -d'/'))
	POSSIBLEENDPOINTS+=($(ip -o -6 addr list ${NETDEVS[$i]} | awk '{print $4}' | cut -f1 -d'/'))
done

ENDPOINTPORT=$(wg show $IFACE listen-port)

echo "Possible endpoint values:"
for (( i=0; i<${#POSSIBLEENDPOINTS[@]}; i++ ))
do
   	echo "[$i] ${POSSIBLEENDPOINTS[$i]}"
done
echo "Select an entry or type in your own value now"
read -p "Endpoint IP/domain? (no port): " ENDPOINT
if [[ $ENDPOINT == +([[:digit:]]) ]]
then
	if [ $ENDPOINT -lt ${#POSSIBLEENDPOINTS[@]} ] || [ $ENDPOINT -ge 0 ]
	then
	ENDPOINT=${POSSIBLEENDPOINTS[$ENDPOINT]}
	fi
fi

read -p "Endpoint port? [$ENDPOINTPORT]: " ENDPOINTPORTTMP
ENDPOINTPORT=${ENDPOINTPORTTMP:-$ENDPOINTPORT}
ENDPOINT="$ENDPOINT:$ENDPOINTPORT"
echo -e "$OKP Endpoint set to: ${BOLD}$ENDPOINT${NC}"

read -p "Peer name? " PEERNAME
echo -e "$OKP Peer file will be written to: ${BOLD}peers/$PEERNAME.conf${NC}"

# get highest ip of all current peers and increment by 1 (assumes that only the last octet is used)
IP=$(wg show $IFACE allowed-ips | awk '{print $2}' | rev | cut -c4- | rev | cut -f4- -d'.' | sort -r | awk 'NR==1')
((IP++))
# get subnet for client ip
SUBNET=$(wg show $IFACE allowed-ips | awk '{print $2}' | rev | cut -c4- | cut -f2- -d'.' | rev | awk 'NR==1')
CLIENTIP="$SUBNET.$IP/32"

read -p "Client IP? [$CLIENTIP]: " CLIENTIPTMP
read -p "AllowedIPs (client)? " ALLOWEDIPS
CLIENTIP=${CLIENTIPTMP:-$CLIENTIP}
echo -e "$OKP Client IP set to: ${BOLD}$CLIENTIP${NC}"
echo -e "$OKP AllowedIPs set to: ${BOLD}$ALLOWEDIPS${NC}"

# generate the keys
wg genkey > privatekey.tmp
cat privatekey.tmp | wg pubkey > pubkey.tmp

# read keys into variables
PRIVATEKEY=$(cat privatekey.tmp)
echo -e "$OKP Generated peer's private key"
PUBLICKEY=$(cat pubkey.tmp)
echo -e "$OKP Generated peer's public key ${BOLD}$PUBLICKEY${NC}"
SERVER_PUBLICKEY=$(wg show $IFACE public-key)

# Generate client and server configs
CONF_SERVER="
[Peer]
# $PEERNAME
PublicKey = $PUBLICKEY
AllowedIPs = $CLIENTIP"

CONF_CLIENT="[Interface]
Address = $CLIENTIP
PrivateKey = $PRIVATEKEY

[Peer]
PublicKey = $SERVER_PUBLICKEY
Endpoint = $ENDPOINT
AllowedIPs = $ALLOWEDIPS
PersistentKeepalive = 25
"

# Write configs to server or client files
mkdir -p "peers"
echo "$CONF_CLIENT" > "peers/$PEERNAME.conf"
echo -e "$OKP Wrote client file to ${BOLD}peers/$PEERNAME.conf${NC}"
echo "$CONF_SERVER" >> "/etc/wireguard/$IFACE.conf"
echo -e "$OKP Appended new client to $IFACE config at ${BOLD}/etc/wireguard/$IFACE.conf${NC}"

wg setconf $IFACE <(wg-quick strip $IFACE)
echo -e "$OKP Reloaded Wireguard interface ${BOLD}$IFACE${NC}"

# remove tmp files
rm privatekey.tmp pubkey.tmp
echo -e "$OKP Removed temporary key files"
echo -e "Done!"
