#!/bin/sh

# Guiderails licensed under the MIT license
# Copyright (c) 2020 Sid Shetye - All Rights Reserved

VERSION=1.0.0
RELEASED="May 20 2020"
SELF=guiderails
NAME=Guiderails
TITLE="Guiderails - whitelisting for a curated internet"

GUIDERAILS_DIR=/opt/share/guiderails
CONF_FILE=$GUIDERAILS_DIR/guiderails.conf
LOG_DIR=/opt/var/log
NW_IP=$(cat $CONF_FILE | awk -F "=" '/^listen-address/ {print $2}')
if type "nvram" > /dev/null; then
    # real router
    NW_INTERFACE=$(nvram get lan_ifname)
    sed -i -E "s/^interface=(.+)/interface=$NW_INTERFACE:guiderails/" "$CONF_FILE"
else
    # linux pc (e.g. test)
    NW_INTERFACE=$(cat $CONF_FILE | awk -F "=" '/^interface/ {print $2}')
    # access as root
    if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
        exit 1
    fi
fi

process_subcommands(){
    case "${1}" in
        "" | "-?" | "-h" | "--help" | "h" | "help"      ) display_help;;
        "start"        ) enable;;
        "stop"         ) disable;;
        "restart"      ) disable
                         enable;;
        *              ) echo "Unknown command: ${@}";;
    esac
}

enable(){
    echo "Enabling" $NAME
    ifconfig $NW_INTERFACE:guiderails $NW_IP up
    dnsmasq --conf-file=$CONF_FILE --log-queries
    pidfile=$(cat $CONF_FILE | awk -F "=" '/^pid-file/ {print $2}')    
    echo "PID is" $(cat $pidfile)
}

disable(){
    echo "Disabling" $NAME
    ifconfig $NW_INTERFACE:guiderails $NW_IP down
    pidfile=$(cat $CONF_FILE | awk -F "=" '/^pid-file/ {print $2}')
    pid=$(cat $pidfile)
    echo "Killing PID" $pid "..."
	{ kill -TERM $pid && wait $pid; } 2>/dev/null

	# paranoid cleanup in case there are orphaned instances. We launch to appear as follows in ps
	# 16470 nobody    3092 S    dnsmasq --conf-file=/opt/share/guiderails/guiderails.conf --log-queries
	orphan_pids=$(ps | grep "dnsmasq.*guiderails.conf" | grep -v "grep" | awk '{print $1}')
	for pid in $orphan_pids
	do 
	    echo "Killing orphaned PID(s)" $pid "..."
		kill -TERM $pid && wait $pid
	done
}

display_help() {    
 echo " Guiderails is a wrapper to DNSMASQ that blacklists everything and then
 selectively whitelists specific servers for a fully controlled and curated
 internet experience. Typical use case is to support young children's online
 education by blocking ALL the internet sites, except for a dozen or two sites
 manually permitted by parents/teachers for a safer online experience.
 Usually, Guiderails' DNSMASQ instance will be an auxiliary DNS server 
 used only by childrens' devices while the rest of the network uses a less 
 restricted primary DNS server. This auxiliary DNS server will run on
 the router itself but on a separate, dedicated virtual IP address
 (e.g. auxiliary on 192.168.1.2 if primary is on 192.168.1.1 and 
 both on the router itself

 Usage: guiderails [option]

 Example: 'guiderails start'

    options are:

    start           starts $NAME
    stop            stops $NAME
    restart         restarts $NAME
    h or help       opens this help menu
    ";

}

print_banner(){
    echo "
    $NW_INTERFACE ($NW_IP) for $NAME auxiliary DNS server

    NOTE: If this seems wrong, edit $CONF_FILE and retry.
    "
}

print_banner
process_subcommands "$@"
