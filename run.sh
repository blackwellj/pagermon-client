#!/usr/bin/env bash

# Set defaults if environment variables are not provided
API_KEY=${API_KEY:-NOKEYSUPPLIED}
PAGER_LOCATION=${PAGER_LOCATION:-UNKNOWN}
FREQUENCY=${FREQUENCY:-153.0750M}
DONGLE_SERIAL=${DONGLE_SERIAL:-00000001}
HOSTNAME=${HOSTNAME:-localhost}

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

# Create reader.sh script to handle rtl_fm and multimon-ng processing
READER_SCRIPT="/pagermon/client/reader.sh"
cat <<EOF > $READER_SCRIPT
#!/usr/bin/env bash

# Output the online message to reader.js
echo "POCSAG512: Address: "0000001"  Function: 0  Alpha: "$PAGER_LOCATION Online"" | node reader.js

# Start rtl_fm and multimon-ng to process the pager data
rtl_fm -d "$DONGLE_SERIAL" -E dc -F 0 -A fast -f "$FREQUENCY" -s 22050 - |
multimon-ng -q -b 1 -c -a POCSAG512 -f alpha -t raw /dev/stdin |echo "POCSAG512: Address: "0000001"  Function: 0  Alpha: "$PAGER_LOCATION Online"" | node reader.js

node /pagermon/client/reader.js
EOF

# Make the reader.sh script executable
chmod +x $READER_SCRIPT

# Execute the reader.sh script
$READER_SCRIPT