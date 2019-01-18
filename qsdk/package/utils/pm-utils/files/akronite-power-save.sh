#!/bin/sh

. /lib/ipq806x.sh
. /lib/functions.sh

akronite_ac_power()
{
	echo "Entering AC-Power Mode"
# Krait Power-UP Sequence
	/etc/init.d/powerctl restart

# Clocks Power-UP Sequence
	echo 400000000 > /sys/kernel/debug/clk/afab_a_clk/rate
	echo 64000000 > /sys/kernel/debug/clk/dfab_a_clk/rate
	echo 64000000 > /sys/kernel/debug/clk/sfpb_a_clk/rate
	echo 64000000 > /sys/kernel/debug/clk/cfpb_a_clk/rate
	echo 133000000 > /sys/kernel/debug/clk/nssfab0_a_clk/rate
	echo 133000000 > /sys/kernel/debug/clk/nssfab1_a_clk/rate
	echo 400000000 > /sys/kernel/debug/clk/ebi1_a_clk/rate

# Enabling Auto scale on NSS cores
	echo 1 > /proc/sys/dev/nss/clock/auto_scale

# PCIe Power-UP Sequence
	sleep 1
	echo 1 > /sys/bus/pci/rcrescan
	sleep 2
	echo 1 > /sys/bus/pci/rescan

	sleep 1

# Bringing Up LAN Interface
	ifup lan

# Sata Power-UP Sequence
	[ -f /sys/devices/platform/msm_sata.0/ahci.0/msm_sata_suspend ] && {
		echo 0 > /sys/devices/platform/msm_sata.0/ahci.0/msm_sata_suspend
	}
	[ -f sys/devices/soc.2/29000000.sata/ipq_ahci_suspend ] && {
		echo 0 > sys/devices/soc.2/29000000.sata/ipq_ahci_suspend
	}

	sleep 1
	echo "- - -" > /sys/class/scsi_host/host0/scan

# USB Power-UP Sequence
	[ -d /sys/module/dwc3_ipq ] || insmod dwc3-ipq
	[ -d /sys/module/dwc3_qcom ] || insmod dwc3-qcom
	[ -d /sys/module/phy_qcom_hsusb ] || insmod phy-qcom-hsusb
	[ -d /sys/module/phy_qcom_ssusb ] || insmod phy-qcom-ssusb
	[ -d /sys/module/dwc3 ] || insmod dwc3

# SD/MMC Power-UP sequence
	local emmcblock="$(find_mmc_part "rootfs")"

	if [ -z "$emmcblock" ]; then
		if [[ -f /tmp/sysinfo/sd_drvname  && ! -d /sys/block/mmcblk0 ]]
		then
			sd_drvname=$(cat /tmp/sysinfo/sd_drvname)
			echo $sd_drvname > /sys/bus/amba/drivers/mmci-pl18x/bind
		fi
	fi

	exit 0
}

akronite_battery_power()
{
	echo "Entering Battery Mode..."

# Wifi Power-down Sequence
	wifi unload

# Bring Down LAN Interface
	ifdown lan

# PCIe Power-Down Sequence

# Remove devices
	sleep 2
	for i in `ls /sys/bus/pci/devices/`; do
		d=/sys/bus/pci/devices/${i}
		v=`cat ${d}/vendor`
		[ "xx${v}" != "xx0x17cb" ] && echo 1 > ${d}/remove
	done

# Remove Buses
	sleep 2
	for i in `ls /sys/bus/pci/devices/`; do
		d=/sys/bus/pci/devices/${i}
		echo 1 > ${d}/remove
	done

# Remove RC
	sleep 2

	[ -f /sys/bus/pci/rcremove ] && {
		echo 1 > /sys/bus/pci/rcremove
	}
	[ -f /sys/devices/pci0000:00/pci_bus/0000:00/rcremove ] && {
		echo 1 > /sys/devices/pci0000:00/pci_bus/0000:00/rcremove
	}
	sleep 1

# Find scsi devices and remove it

	partition=`cat /proc/partitions | awk -F " " '{print $4}'`

	for entry in $partition; do
		sd_entry=$(echo $entry | head -c 2)

		if [ "$sd_entry" = "sd" ]; then
			[ -f /sys/block/$entry/device/delete ] && {
				echo 1 > /sys/block/$entry/device/delete
			}
		fi
	done

# Sata Power-Down Sequence
	[ -f /sys/devices/platform/msm_sata.0/ahci.0/msm_sata_suspend ] && {
		echo 1 > /sys/devices/platform/msm_sata.0/ahci.0/msm_sata_suspend
	}
	[ -f /sys/devices/soc.2/29000000.sata/ipq_ahci_suspend ] && {
		echo 1 > /sys/devices/soc.2/29000000.sata/ipq_ahci_suspend
	}

# USB Power-down Sequence
	[ -d /sys/module/dwc3_ipq ] && rmmod dwc3-ipq
	[ -d /sys/module/dwc3 ] && rmmod dwc3
	[ -d /sys/module/dwc3_qcom ] && rmmod dwc3-qcom
	[ -d /sys/module/phy_qcom_hsusb ] && rmmod phy-qcom-hsusb
	[ -d /sys/module/phy_qcom_ssusb ] && rmmod phy-qcom-ssusb

	sleep 1

#SD/MMC Power-down Sequence
	local emmcblock="$(find_mmc_part "rootfs")"

	if [ -z "$emmcblock" ]; then
		if [ -d /sys/block/mmcblk0 ]
		then
			sd_drvname=`readlink /sys/block/mmcblk0 | awk -F "/" '{print $5}'`
			echo "$sd_drvname" > /tmp/sysinfo/sd_drvname
			echo $sd_drvname > /sys/bus/amba/drivers/mmci-pl18x/unbind
		fi
	fi

# Disabling Auto scale on NSS cores
	echo 0 > /proc/sys/dev/nss/clock/auto_scale

# Clocks Power-down Sequence

	echo 400000000 > /sys/kernel/debug/clk/afab_a_clk/rate
	echo 32000000 > /sys/kernel/debug/clk/dfab_a_clk/rate
	echo 32000000 > /sys/kernel/debug/clk/sfpb_a_clk/rate
	echo 32000000 > /sys/kernel/debug/clk/cfpb_a_clk/rate
	echo 133000000 > /sys/kernel/debug/clk/nssfab0_a_clk/rate
	echo 133000000 > /sys/kernel/debug/clk/nssfab1_a_clk/rate
	echo 400000000 > /sys/kernel/debug/clk/ebi1_a_clk/rate

# Scaling Down UBI Cores
	echo 110000000 > /proc/sys/dev/nss/clock/current_freq

# Krait Power-down Sequence
	echo 384000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
	echo 384000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq
	echo "powersave" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
	echo "powersave" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
}

ap_dk01_1_ac_power()
{
	echo "Entering AC-Power Mode"
# Cortex Power-UP Sequence
	/etc/init.d/powerctl restart

# Power on Malibu PHY of LAN ports
	ssdk_sh port poweron set 1
	ssdk_sh port poweron set 2
	ssdk_sh port poweron set 3
	ssdk_sh port poweron set 4
# Wifi Power-up Sequence
	wifi up

# USB Power-UP Sequence
	if ! [ -d /sys/module/dwc3_ipq40xx ]
	then
		insmod phy-qca-baldur.ko
		insmod phy-qca-uniphy.ko
		insmod dwc3-ipq40xx.ko
		insmod dwc3.ko
	fi

# LAN interface up
	ifup lan

	exit 0
}

ap_dk01_1_battery_power()
{
	echo "Entering Battery Mode..."

# Wifi Power-down Sequence
	wifi unload

# Find scsi devices and remove it

	partition=`cat /proc/partitions | awk -F " " '{print $4}'`

	for entry in $partition; do
		sd_entry=$(echo $entry | head -c 2)

		if [ "$sd_entry" = "sd" ]; then
			[ -f /sys/block/$entry/device/delete ] && {
				echo 1 > /sys/block/$entry/device/delete
			}
		fi
	done

# Power off Malibu PHY of LAN ports
	ssdk_sh port poweroff set 1
	ssdk_sh port poweroff set 2
	ssdk_sh port poweroff set 3
	ssdk_sh port poweroff set 4

# USB Power-down Sequence
	if [ -d /sys/module/dwc3_ipq40xx ]
	then
		rmmod dwc3
		rmmod dwc3-ipq40xx
		rmmod phy-qca-uniphy
		rmmod phy-qca-baldur
	fi
	sleep 2

# LAN interface down
	ifdown lan

# Cortex Power-down Sequence
	echo 48000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
	echo "powersave" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
}

ap_dk04_1_ac_power()
{
	echo "Entering AC-Power Mode"
# Cortex Power-UP Sequence
	/etc/init.d/powerctl restart

# Power on Malibu PHY of LAN ports
	ssdk_sh port poweron set 1
	ssdk_sh port poweron set 2
	ssdk_sh port poweron set 3
	ssdk_sh port poweron set 4

# PCIe Power-UP Sequence
	sleep 1
	echo 1 > /sys/bus/pci/rcrescan
	sleep 2
	echo 1 > /sys/bus/pci/rescan

	sleep 1

# Wifi Power-up Sequence
	wifi up

# USB Power-UP Sequence
	if ! [ -d /sys/module/dwc3_ipq40xx ]
	then
		insmod phy-qca-baldur.ko
		insmod phy-qca-uniphy.ko
		insmod dwc3-ipq40xx.ko
		insmod dwc3.ko
	fi

# LAN interface up
	ifup lan

# SD/MMC Power-UP sequence
	local emmcblock="$(find_mmc_part "rootfs")"

	if [ -z "$emmcblock" ]; then
		if [[ -f /tmp/sysinfo/sd_drvname  && ! -d /sys/block/mmcblk0 ]]
		then
			sd_drvname=$(cat /tmp/sysinfo/sd_drvname)
			echo $sd_drvname > /sys/bus/platform/drivers/sdhci_msm/bind
		fi
	fi

	sleep 1

	exit 0
}

ap_dk04_1_battery_power()
{
	echo "Entering Battery Mode..."


# PCIe Power-Down Sequence

# Remove devices
	sleep 2
	for i in `ls /sys/bus/pci/devices/`; do
		d=/sys/bus/pci/devices/${i}
		v=`cat ${d}/vendor`
		[ "xx${v}" != "xx0x17cb" ] && echo 1 > ${d}/remove
	done

# Remove Buses
	sleep 2
	for i in `ls /sys/bus/pci/devices/`; do
		d=/sys/bus/pci/devices/${i}
		echo 1 > ${d}/remove
	done

# Remove RC
	sleep 2

	[ -f /sys/bus/pci/rcremove ] && {
		echo 1 > /sys/bus/pci/rcremove
	}
	[ -f /sys/devices/pci0000:00/pci_bus/0000:00/rcremove ] && {
		echo 1 > /sys/devices/pci0000:00/pci_bus/0000:00/rcremove
	}
	sleep 1

# Wifi Power-down Sequence
	wifi unload

# Find scsi devices and remove it

	partition=`cat /proc/partitions | awk -F " " '{print $4}'`

	for entry in $partition; do
		sd_entry=$(echo $entry | head -c 2)

		if [ "$sd_entry" = "sd" ]; then
			[ -f /sys/block/$entry/device/delete ] && {
				echo 1 > /sys/block/$entry/device/delete
			}
		fi
	done

# Power off Malibu PHY of LAN ports
	ssdk_sh port poweroff set 1
	ssdk_sh port poweroff set 2
	ssdk_sh port poweroff set 3
	ssdk_sh port poweroff set 4

# USB Power-down Sequence
	if [ -d /sys/module/dwc3_ipq40xx ]
	then
		rmmod dwc3
		rmmod dwc3-ipq40xx
		rmmod phy-qca-uniphy
		rmmod phy-qca-baldur
	fi
	sleep 2
#SD/MMC Power-down Sequence
	local emmcblock="$(find_mmc_part "rootfs")"

	if [ -z "$emmcblock" ]; then
		if [ -d /sys/block/mmcblk0 ]
		then
			sd_drvname=`readlink /sys/block/mmcblk0 | awk -F "/" '{print $4}'`
			echo "$sd_drvname" > /tmp/sysinfo/sd_drvname
			echo $sd_drvname > /sys/bus/platform/drivers/sdhci_msm/unbind
		fi
	fi

# LAN interface down
	ifdown lan

# Cortex Power-down Sequence
	echo 48000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
	echo "powersave" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
}

local board=$(ipq806x_board_name)
case "$1" in
	false)
		case "$board" in
		db149 | ap148 | ap145 | ap148_1xx | db149_1xx | db149_2xx | ap145_1xx | ap160 | ap160_2xx | ap161 | ak01_1xx)
			akronite_ac_power ;;
		ap-dk01.1-c1 | ap-dk01.1-c2)
			ap_dk01_1_ac_power ;;
		ap-dk04.1-c1 | ap-dk04.1-c2 | ap-dk04.1-c3 | ap-dk04.1-c4 | ap-dk06.1-c1 | ap-dk07.1-c1)
			ap_dk04_1_ac_power ;;
		esac ;;
	true)
		case "$board" in
		db149 | ap148 | ap145 | ap148_1xx | db149_1xx | db149_2xx | ap145_1xx | ap160 | ap160_2xx | ap161 | ak01_1xx)
			akronite_battery_power ;;
		ap-dk01.1-c1 | ap-dk01.1-c2)
			ap_dk01_1_battery_power ;;
		ap-dk04.1-c1 | ap-dk04.1-c2 | ap-dk04.1-c3 | ap-dk04.1-c4 | ap-dk06.1-c1 | ap-dk07.1-c1)
			ap_dk04_1_battery_power ;;
		esac ;;
esac
