# obudpst <= 9.0.0-1's %preun removed the alternative on upgrade too, and it
# runs after this package's %post: register again, with the selection %post
# saved. A no-op when the registration survived.
if [ -x /usr/lib/obudpst/udpst ] && [ -r /usr/share/udpst/functions.sh ]; then
    . /usr/share/udpst/functions.sh
    saved=$UDPST_STATE_DIR/obudpst-posttrans
    if ! udpst_alt_has /usr/lib/obudpst/udpst; then
        [ -f "$saved" ] && mv -f "$saved" "$UDPST_ALT_SAVED"
        udpst_alt_register /usr/lib/obudpst/udpst 50
        udpst_service_refresh
    fi
    rm -f "$saved"
fi
