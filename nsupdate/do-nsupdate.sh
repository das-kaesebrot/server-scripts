#!/bin/bash

# Change these variables
KEY="/path/to/your/key.conf"
DOMAINS=("1.dyn.example.com" "2.dyn.example.com")
ZONE="dyn.example.com"
SERVER="ns1.example.com"

# Required internal variables, do not change these
RECORDS=""
NS_IP=$(dig +short ${DOMAINS[0]} @$SERVER A)
EXT_IP=$(wget -4 -qO- http://ifconfig.co/ip)
NEW_LINE=$'\n'

# Only update if IP is different than the one on the nameserver
# (checks with first domain of array)
if [ "$NS_IP" != "$EXT_IP" ]; then
    for DOMAIN in "${DOMAINS[@]}"; do
        RECORDS+="update delete $DOMAIN. A$NEW_LINE"
        RECORDS+="update add $DOMAIN. 600 A $EXT_IP$NEW_LINE"
    done

    echo -e "IP change detected.
External IPv4: $EXT_IP
IPv4 on nameserver: $NS_IP
Running update...
"

cat<< EOF | nsupdate -k "$KEY"
server $SERVER
zone $ZONE
$(echo -e "$RECORDS")
show
send
EOF

    echo "Done!"
else
    echo "No IP change detected, skipping update."
fi