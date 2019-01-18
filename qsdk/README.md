# OpenWRT _Hue Bridge_ fork

Welcome to the OpenWRT / QSDK _Hue Bridge_ fork.

Some _Hue Bridge_ requirements mandated modifications to the upstream [OpenWRT / QSDK project](https://www.codeaurora.org/project/qsdk). This documents changes rationale.

For more information refer to the [upstream OpenWRT project](https://openwrt.org/).

## Network configuration

_TODO_

[Network interface daemon (netifd)](./package/network/config/netifd/files/lib/netifd):
* [dhcp.script](./package/network/config/netifd/files/lib/netifd/dhcp.script)

## Time synchronization

The _Hue System_ is dependent on robust security mechanisms such as [Public key certificates](https://en.wikipedia.org/wiki/Public_key_certificate#Vendor_defined_classes). For these to operate correctly, the _Hue Bridge_ must reasonably synchronized world time. The default mechanism provided by OpenWRT; [NTP](https://en.wikipedia.org/wiki/Network_Time_Protocol); has proven to be unreliable in some home network environments. The NTP daemon provided also proved to get stuck under certain conditions. To overcome these problems, the following improvements are implemented:

1. The NTP start script; [sysntpd](./package/utils/busybox/files/sysntpd); starts a monitor program; [ntpd-monitor](./package/utils/busybox/files/ntpd-monitor).
1. The monitor program gives NTP 5 minutes to synchronize the clock. If NTP is unable to do so, both the above are restarted. See [ntpd.script](./package/utils/busybox/files/ntpd.script).
1. Once NTP is able to synchronize the clock, the monitor program is stopped and no longer used.
1. As long as NTP has not yet synchronized the time, the monitor program synchronizes the clock with an alternative time synchronization mechanism; [tlsdate](./package/network/utils/tlsdate); every time it is restarted.

To keep the above code clean and readable, [utils.sh](./package/utils/busybox/files/utils.sh), is provided.
 
