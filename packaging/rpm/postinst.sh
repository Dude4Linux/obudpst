# rpm/dnf run scriptlets without a terminal, so this cannot ask whether to
# become the default: when another implementation already is, it stays the
# default. The shared logic is in udpst-common's functions.sh.
. /usr/share/udpst/functions.sh
udpst_alt_register /usr/lib/obudpst/udpst 50
if [ "$1" -gt 1 ]; then
    # Upgrade: obudpst <= 9.0.0-1's %preun removes the alternative after
    # this scriptlet. Keep the selection for %posttrans to put back.
    udpst_alt_save "$UDPST_STATE_DIR/obudpst-posttrans"
fi
udpst_service_refresh
