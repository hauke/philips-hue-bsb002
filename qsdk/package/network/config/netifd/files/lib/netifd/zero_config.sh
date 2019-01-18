#!/bin/sh

AVAHI_VAR_DIR=/var/lib/avahi-autoipd

avahi_daemon() {
	IFNAME=$(uci get network.${INTERFACE}.ifname)
	INTERFACE=${INTERFACE} avahi-autoipd $1 ${IFNAME}
	logger -t avahi-autoipd -p daemon.info "INTERFACE=${INTERFACE}"
}

wait_until_avahi_exits() {
	while pidof avahi-autoipd >/dev/null; do
		sleep 1
	done
	logger -t avahi-autoipd -p daemon.info "stopped"
}

zero_config() {
	logger -t avahi-autoipd -p daemon.info "$1"
	case $1 in
	start)
		mkdir -p ${AVAHI_VAR_DIR}
		avahi_daemon -D
		;;
	stop)
		avahi_daemon -k
		wait_until_avahi_exits
		;;
	esac
}
