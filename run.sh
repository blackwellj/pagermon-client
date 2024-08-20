#!/usr/bin/env bash

rtl_fm -d 00000102 -E dc -F 0 -A fast -f 153.0750M -s22050 - |
multimon-ng -q -b1 -c -a POCSAG512 -f alpha -t raw /dev/stdin |
node reader.js

#exec tail -f /dev/null
