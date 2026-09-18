#!/bin/sh
set -e

if command -v update-alternatives >/dev/null 2>&1; then
    ALT_CMD=update-alternatives
elif command -v alternatives >/dev/null 2>&1; then
    ALT_CMD=alternatives
else
    exit 0
fi

"$ALT_CMD" --remove udpst /usr/lib/obudpst/udpst
