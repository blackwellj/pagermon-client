#!/usr/bin/env bash

set -e

API_KEY=${API_KEY:-NOKEYSUPPLIED}
PAGER_LOCATION=${PAGER_LOCATION:-UNKNOWN}
FREQUENCY=${FREQUENCY:-153.0750M}
DONGLE_SERIAL=${DONGLE_SERIAL:-00000001}
HOSTNAME=${HOSTNAME:-localhost}

CONFIG_FILE="/pagermon/client/config/default.json"
READER_SCRIPT="/pagermon/client/reader.sh"

cat <<EOF > "$CONFIG_FILE"
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

cat <<'EOF' > "$READER_SCRIPT"
#!/usr/bin/env bash

DONGLE_SERIAL="${DONGLE_SERIAL:-00000001}"
FREQUENCY="${FREQUENCY:-153.0750M}"
PAGER_LOCATION="${PAGER_LOCATION:-UNKNOWN}"

cd /pagermon/client || exit 1

echo "Waiting for RTL-SDR dongle serial ${DONGLE_SERIAL}..."

while true; do
    if rtl_test -d "$DONGLE_SERIAL" -t >/tmp/rtl_test.log 2>&1; then
        echo "RTL-SDR dongle found: ${DONGLE_SERIAL}"
        break
    fi

    echo "Dongle not found. Retrying in 10 seconds..."
    sleep 10
done

echo "Sending online message..."

printf 'POCSAG512: Address: 1025091  Function: 0  Alpha: %s Online\n' "$PAGER_LOCATION" | node reader.js

echo "Starting pager decoder on ${FREQUENCY}..."

rtl_fm -d "$DONGLE_SERIAL" -E dc -F 0 -A fast -f "$FREQUENCY" -s 22050 - 2>/tmp/rtl_fm.log | \
multimon-ng -q -b 1 -c -a POCSAG512 -f alpha -t raw /dev/stdin | \
node reader.js
EOF

chmod +x "$READER_SCRIPT"

exec "$READER_SCRIPT"
