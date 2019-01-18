#!/bin/sh

sort_and_remove_duplicates() {
	echo "$*" | xargs -n 1 | sort -u | xargs
}

ntp_update_servers() {
	local ntpsrv="$*"
	local currentList="`uci get -q system.ntp.server`"
	local defaultList="`uci get -q system.ntp_default.server`"

	logger -t dhcp -p daemon.info "ntp servers: suggested: ${ntpsrv}"

	local newList="`sort_and_remove_duplicates ${defaultList} ${ntpsrv}`"

	if [ "${currentList}" == "${newList}" ]; then
		logger -t dhcp -p daemon.notice "ntp servers: up-to-date"
		return 0
	fi

	if uci set system.ntp.server="${newList}" && uci commit system; then
		logger -t dhcp -p daemon.notice "ntp servers: updated"
		return 0
	fi

	logger -t dhcp -p daemon.error "ntp servers: cannot update"
	return 1
}

has_value_changed() {
	local NAME=$1;shift
	local NEW_VALUE="$1"
	local STATE_FILE=/var/dhcp/${NAME}.prev
	local PREV_VALUE="`cat ${STATE_FILE} 2>/dev/null`"
	if [ "${NEW_VALUE}" != "${PREV_VALUE}" ]; then
		mkdir -p `dirname ${STATE_FILE}`
		echo -n "${NEW_VALUE}" >${STATE_FILE}
		return 0
	else
		return 1
	fi
}

ntp_servers_changed() {
	has_value_changed ntp_servers "`uci get -q system.ntp.server`"
}

ntp_gateway_changed() {
	# Track changes to the PROTO_ROUTE global variable which is adjusted when
	# proto_add_ipv4_route() is called above in setup_interface(). 
	has_value_changed gateway "${PROTO_ROUTE}"
}

ntp_restart_if_needed() {
	local CHANGES=""
	ntp_gateway_changed && CHANGES="${CHANGES} gateway"
	ntp_servers_changed && CHANGES="${CHANGES} ntp_servers"
	if [ -n "${CHANGES}" ]; then
		logger -t dhcp -p daemon.notice "restart ntp: changes in:${CHANGES}"
		/etc/init.d/sysntpd restart
	fi
}

ntp_stop() {
	ntp_gateway_changed
	logger -t dhcp -p daemon.notice "stop ntp: network down"
	/etc/init.d/sysntpd stop
}


