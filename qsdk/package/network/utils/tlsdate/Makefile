#
# Copyright (C) 2017 Philips Lighting B.V.
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=tlsdate
PKG_VERSION:=2016-11-23
PKG_SOURCE_VERSION:=tlsdate-0.0.13
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ioerror/tlsdate.git
PKG_MD5SUM:=c555eb0c4a4724a03f0e82696a3e048c
PKG_INSTALL:=1
PKG_FIXUP:=autoreconf
PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE license-fixups/tlsdate-ca-roots.conf.txt

include $(INCLUDE_DIR)/package.mk

define Package/tlsdate
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+libopenssl +libevent2-core
  TITLE:=secure parasitic rdate replacement
  URL:=https://www.github.com/ioerror/tlsdate
endef

define Package/tlsdate/description
 tlsdate sets the local clock by securely connecting with TLS to remote
 servers and extracting the remote time out of the secure handshake. Unlike
 ntpdate, tlsdate uses TCP, for instance connecting to a remote HTTPS or TLS
 enabled service, and provides some protection against adversaries that try to
 feed you malicious time information.
endef

define Package/tlsdate/conffiles
/etc/tlsdate/tlsdated.conf
/etc/tlsdate/ca-roots/tlsdate-ca-roots.conf
endef

CONFIGURE_ARGS += \
	--with-ssl-dir="$(STAGING_DIR)/usr" \
	--enable-seccomp-filter=no \

CONFIGURE_VARS += \
	CROSS_COMPILE="yes" \

# pass CFLAGS again to override -O2 set by configure
MAKE_FLAGS += \
	CFLAGS="$(TARGET_CFLAGS)" \

define Package/tlsdate/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/tlsdate $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/tlsdate-helper $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc/tlsdate/
	$(INSTALL_DIR) $(1)/etc/tlsdate/ca-roots/
	$(INSTALL_CONF) $(PKG_INSTALL_DIR)/etc/tlsdate/tlsdated.conf $(1)/etc/tlsdate/tlsdated.conf
	$(INSTALL_CONF) $(PKG_INSTALL_DIR)/etc/tlsdate/ca-roots/tlsdate-ca-roots.conf $(1)/etc/tlsdate/ca-roots/tlsdate-ca-roots.conf
endef

$(eval $(call BuildPackage,tlsdate))
