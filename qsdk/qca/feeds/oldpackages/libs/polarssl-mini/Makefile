# 
# Copyright (c) 2015 The Linux Foundation. All rights reserved.
# Copyright (C) 2006 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id: Makefile 12228 2008-08-06 22:43:15Z nbd $

include $(TOPDIR)/rules.mk

PKG_NAME:=polarssl-mini
PKG_VERSION:=1.3.4
PKG_RELEASE:=1
PKG_USE_MIPS16:=0

PKG_SOURCE:=polarssl-$(PKG_VERSION)-gpl.tgz
PKG_SOURCE_URL:=https://polarssl.org/code/releases/
PKG_MD5SUM:=30a75c5f171be49f805f3bf64a0af054

PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/polarssl-mini
  SUBMENU:=SSL
  TITLE:=Embedded SSL(mini)
  SECTION:=libs
  CATEGORY:=Libraries
  ABI_VERSION:=$(PKG_VERSION)
  URL:=http://polarssl.org/
endef

define Package/polarssl-mini/description
Static library only for sha256 sum and RSA verification, derived from polarssl.
endef

define Build/Prepare
	$(TAR) -C $(DL_DIR) -zxf $(DL_DIR)/polarssl-$(PKG_VERSION)-gpl.tgz
	rm -rf $(PKG_BUILD_DIR)
	mv $(DL_DIR)/polarssl-$(PKG_VERSION) $(PKG_BUILD_DIR)
	$(Build/Patch)
endef

define Build/Compile
endef

POLARSSL-MINI-SOURCES = \
	$(PKG_BUILD_DIR)/include/polarssl/asn1.h \
	$(PKG_BUILD_DIR)/include/polarssl/bignum.h \
	$(PKG_BUILD_DIR)/include/polarssl/bn_mul.h \
	$(PKG_BUILD_DIR)/include/polarssl/md.h \
	$(PKG_BUILD_DIR)/include/polarssl/md_wrap.h \
	$(PKG_BUILD_DIR)/include/polarssl/oid.h \
	$(PKG_BUILD_DIR)/include/polarssl/rsa.h \
	$(PKG_BUILD_DIR)/include/polarssl/sha256.h \
	$(PKG_BUILD_DIR)/library/asn1parse.c \
	$(PKG_BUILD_DIR)/library/bignum.c \
	$(PKG_BUILD_DIR)/library/md.c \
	$(PKG_BUILD_DIR)/library/md_wrap.c \
	$(PKG_BUILD_DIR)/library/oid.c \
	$(PKG_BUILD_DIR)/library/rsa.c \
	$(PKG_BUILD_DIR)/library/sha256.c


define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/polarssl-mini
	$(foreach header_file,$(POLARSSL-MINI-SOURCES), $(CP) $(header_file) $(1)/usr/include/polarssl-mini;)
endef

define Package/polarssl-mini/install
endef

$(eval $(call BuildPackage,polarssl-mini))
