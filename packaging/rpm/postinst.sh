#!/bin/sh
set -e

if command -v update-alternatives >/dev/null 2>&1; then
    ALT_CMD=update-alternatives
elif command -v alternatives >/dev/null 2>&1; then
    ALT_CMD=alternatives
else
    echo "obudpst: no alternatives system found; /usr/bin/udpst not linked" >&2
    exit 0
fi

"$ALT_CMD" --install /usr/bin/udpst udpst /usr/lib/obudpst/udpst 50
