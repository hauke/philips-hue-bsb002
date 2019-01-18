#!/bin/sh

. /lib/functions.sh
. ../zero_config.sh
. ../ntp.sh
. ../netifd-proto.sh
init_proto "$@"

proto_dhcp_init_config() {
	logger -t dhcp -p daemon.info "init config"
	renew_handler=1

	proto_config_add_string 'ipaddr:ipaddr'
	proto_config_add_string 'hostname:hostname'
	proto_config_add_string clientid
	proto_config_add_string vendorid
	proto_config_add_boolean 'broadcast:bool'
	proto_config_add_string 'reqopts:list(string)'
	proto_config_add_string iface6rd
	proto_config_add_string sendopts
	proto_config_add_boolean delegate
	proto_config_add_string zone6rd
	proto_config_add_string zone
	proto_config_add_string mtu6rd
	proto_config_add_string customroutes
}

proto_dhcp_setup() {
	logger -t dhcp -p daemon.info "setup"
	local config="$1"
	local iface="$2"

	local ipaddr hostname clientid vendorid broadcast reqopts iface6rd sendopts delegate zone6rd zone mtu6rd customroutes
	json_get_vars ipaddr hostname clientid vendorid broadcast reqopts iface6rd sendopts delegate zone6rd zone mtu6rd customroutes

	# hue: avoid requesting a specific IP address on discovery
	unset ipaddr
	# hue: default list of request options with 'hostname' removed
	[ -n "$reqopts" ] || reqopts="1 3 6 15 28 42"

	local opt dhcpopts
	[ -n "$reqopts" ] && append dhcpopts "--no-default-options"
	for opt in $reqopts; do
		append dhcpopts "-O $opt"
	done

	for opt in $sendopts; do
		append dhcpopts "-x $opt"
	done

	[ "$broadcast" = 1 ] && broadcast="-B" || broadcast=
	[ -n "$clientid" ] && clientid="-x 0x3d:${clientid//:/}" || clientid="-C"
	[ -n "$iface6rd" ] && proto_export "IFACE6RD=$iface6rd"
	[ "$iface6rd" != 0 -a -f /lib/netifd/proto/6rd.sh ] && append dhcpopts "-O 212"
	[ -n "$zone6rd" ] && proto_export "ZONE6RD=$zone6rd"
	[ -n "$zone" ] && proto_export "ZONE=$zone"
	[ -n "$mtu6rd" ] && proto_export "MTU6RD=$mtu6rd"
	[ -n "$customroutes" ] && proto_export "CUSTOMROUTES=$customroutes"
	[ "$delegate" = "0" ] && proto_export "IFACE6RD_DELEGATE=0"

	proto_export "INTERFACE=$config"
	proto_run_command "$config" udhcpc \
		-p /var/run/udhcpc-$iface.pid \
		-s /lib/netifd/dhcp.script \
		-f -t 0 -i "$iface" \
		${ipaddr:+-r $ipaddr} \
		${hostname:+-H $hostname} \
		${vendorid:+-V $vendorid} \
		$clientid $broadcast $dhcpopts
}

proto_dhcp_renew() {
	logger -t dhcp -p daemon.info "renew"
	local interface="$1"
	# SIGUSR1 forces udhcpc to renew its lease
	local sigusr1="$(kill -l SIGUSR1)"
	[ -n "$sigusr1" ] && proto_kill_command "$interface" $sigusr1
}

proto_dhcp_teardown() {
	logger -t dhcp -p daemon.info "teardown"
	INTERFACE=$1 zero_config stop 
	local interface="$1"
	proto_kill_command "$interface"
	ntp_stop
}

add_protocol dhcp
