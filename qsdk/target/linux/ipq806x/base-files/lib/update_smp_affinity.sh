#!/bin/sh
#
# Copyright (c) 2015 The Linux Foundation. All rights reserved.
# Copyright (C) 2011 OpenWrt.org

. /lib/ipq806x.sh

enable_smp_affinity_wifi() {
	irq_wifi0=`grep -E -m1 'ath10k' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`
	irq_wifi1=`grep -E -m2 'ath10k' /proc/interrupts | cut -d ':' -f 1 | tail -n1 | tr -d ' '`

	# Enable smp_affinity for ath10k driver
	if [ -n "$irq_wifi0" ]; then
		board=$(ipq806x_board_name)

		case "$board" in
			ap-dk0*)
				echo 4 > /proc/irq/$irq_wifi0/smp_affinity
				[ -n "$irq_wifi1" ] && {
				echo 8 > /proc/irq/$irq_wifi1/smp_affinity
				}
			;;
			ap148*)
				echo 2 > /proc/irq/$irq_wifi0/smp_affinity
			;;
		esac
	else
	# Enable smp_affinity for qca-wifi driver
		board=$(ipq806x_board_name)
		device="$1"
		hwcaps=$(cat /sys/class/net/$device/hwcaps)

		[ -n "$device" ] && {
		irq_affinity_num=`grep $device /proc/interrupts | cut -d ':' -f 1 | tr -d ' '`
		}

		case "${hwcaps}" in
			*11an/ac)
				smp_affinity=2
			;;
			*)
				smp_affinity=1
		esac

		case "$board" in
			ap-dk0*)
			if [ $device == "wifi2" ]; then
				# Assign core 1 for wifi2. For ap-dkXX,wifi2 is always the third radio
				smp_affinity=2
			else
				# Assign Core 3 (or) 4 for Dakota based on hwcaps
				smp_affinity=$(($smp_affinity << 2))
			fi
			;;
		esac

		[ -n "$irq_affinity_num" ] && echo $smp_affinity > /proc/irq/$irq_affinity_num/smp_affinity
	fi
}
