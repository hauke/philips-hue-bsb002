#
# Copyright (C) 2007-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=tcpdump
PKG_VERSION:=4.5.1
PKG_RELEASE:=4

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://www.tcpdump.org/release/ \
	http://ftp.gwdg.de/pub/misc/tcpdump/ \
	http://www.at.tcpdump.org/ \
	http://www.br.tcpdump.org/
PKG_MD5SUM:=973a2513d0076e34aa9da7e15ed98e1b

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_PARALLEL:=1

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE

PKG_MAINTAINER:=Felix Fietkau <nbd@openwrt.org>
PKG_LICENSE:=BSD-3-Clause

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/tcpdump/default
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+libpcap
  TITLE:=Network monitoring and data acquisition tool
  URL:=http://www.tcpdump.org/
endef

define Package/tcpdump/Default/attributions
  This product includes software developed by the University of California, Berkeley and its contributors.
  This product includes software developed by the Computer Systems Engineering Group at Lawrence Berkeley Laboratory.
  This product includes software developed by the Kungliga Tekniska Högskolan and its contributors.
  This product includes software developed by Jason L. Wright.
  This product includes software developed by the NetBSD Foundation, Inc. and its contributors.
  This product includes software developed by Yen Yen Lim and North Dakota State University.
  This product includes software developed by Bruce M. Simpson.
  This product includes software developed by Michael Shalayeff.
endef

define Package/tcpdump
  $(Package/tcpdump/default)
  VARIANT:=full
endef

define Package/tcpdump/attributions
  $(call Package/tcpdump/Default/attributions)
endef

define Package/tcpdump-mini
  $(Package/tcpdump/default)
  TITLE+= (minimal version)
  VARIANT:=mini
endef

define Package/tcpdump-mini/attributions
  $(call Package/tcpdump/Default/attributions)
endef

CONFIGURE_ARGS += \
	--without-crypto

ifeq ($(CONFIG_IPV6),y)
CONFIGURE_ARGS += \
	--enable-ipv6
endif

TARGET_CFLAGS += -ffunction-sections -fdata-sections
TARGET_LDFLAGS += -Wl,--gc-sections

CONFIGURE_VARS += \
	BUILD_CC="$(TARGET_CC)" \
	HOSTCC="$(HOSTCC)" \
	td_cv_buggygetaddrinfo="no" \
	ac_cv_linux_vers=$(LINUX_VERSION) \
	ac_cv_header_rpc_rpcent_h=no \
	ac_cv_lib_rpc_main=no \
	ac_cv_path_PCAP_CONFIG=""

MAKE_FLAGS :=

ifeq ($(BUILD_VARIANT),mini)
  TARGET_CFLAGS += -DTCPDUMP_MINI
  CONFIGURE_ARGS += --disable-smb
  MAKE_FLAGS += TCPDUMP_MINI=1
endif

MAKE_FLAGS += \
	CCOPT="$(TARGET_CFLAGS)" INCLS="-I. $(TARGET_CPPFLAGS)"


define Package/tcpdump/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/tcpdump $(1)/usr/sbin/
endef

Package/tcpdump-mini/install = $(Package/tcpdump/install)

$(eval $(call BuildPackage,tcpdump))
$(eval $(call BuildPackage,tcpdump-mini))
