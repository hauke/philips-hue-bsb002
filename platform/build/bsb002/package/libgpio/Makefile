#
# Copyright (C) 2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=libgpio
PKG_VERSION:=2015-01-15
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/Linutronix/libgpio.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=0356a62b38919401f189df7a60b7dae5d4f1e32e
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

PKG_LICENSE:=LGPL-2.1

include $(INCLUDE_DIR)/package.mk

define Package/libgpio
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=gpio library
  URL:=https://github.com/Linutronix/libgpio/
  DEPENDS:=+libconfig
endef

define Package/libgpio/description
  libgpio can be used to ease the access of GPIOs via Linux / sysfs.
endef

define Build/Configure
	(cd $(PKG_BUILD_DIR) && $(BASH) -x ./autogen.sh)
	$(call Build/Configure/Default)
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_BUILD_DIR)/include/gpio.h $(1)/usr/include/

	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/src/.libs/libgpio*.{a,so*} $(1)/usr/lib/
endef

define Package/libgpio/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/src/.libs/libgpio*.{a,so*} $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libgpio))

