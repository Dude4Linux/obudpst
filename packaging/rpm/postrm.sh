# Fall back to the other implementation, or stop the server (fail closed).
if [ "$1" = "0" ] && [ -r /usr/share/udpst/functions.sh ]; then
    . /usr/share/udpst/functions.sh
    udpst_service_refresh
fi
