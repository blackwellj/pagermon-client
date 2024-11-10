#!/usr/bin/env bash

# Set defaults if environment variables are not provided
API_KEY=${API_KEY:}
PAGER_LOCATION=${PAGER_LOCATION}
FREQUENCY=${FREQUENCY:-153.0750M}
DONGLE_SERIAL=${DONGLE_SERIAL:-00000002}
HOSTNAME=${HOSTNAME}

# Path to the client configuration file
CONFIG_FILE="/pagermon/client/config/default.json"

# Update the client configuration file with the environment variables
cat <<EOF > $CONFIG_FILE
{
    "apikey": "${API_KEY}",
    "hostname": "${HOSTNAME}",
    "identifier": "${PAGER_LOCATION}",
    "sendFunctionCode": false,
    "useTimestamp": true,
    "EAS": {
        "excludeEvents": [],
        "includeFIPS": [],
        "addressAddType": true
    }
}
EOF

# Use environment variables in the rtl_fm command
rtl_fm -d "$DONGLE_SERIAL" -E dc -F 0 -A fast -f "$FREQUENCY" -s 22050 - |
multimon-ng -q -b 1 -c -a POCSAG512 -f alpha -t raw /dev/stdin |
node /pagermon/client/reader.js

#exec tail -f /dev/null
