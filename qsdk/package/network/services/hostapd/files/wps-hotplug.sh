#!/bin/sh

if [ "$ACTION" = "pressed" -a "$BUTTON" = "wps" ]; then
	cd /var/run/hostapd
	for socket in *; do
		[ -S "$socket" ] || continue
		hostapd_cli -i "$socket" wps_pbc
	done
	for dir in /var/run/wpa_supplicant*; do
		[ -d "$dir" ] || continue
		wpa_cli -p "$dir" wps_pbc
	done
fi

return 0
