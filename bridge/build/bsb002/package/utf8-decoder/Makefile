# Copyright (C) 2017 Philips Lighting

include $(TOPDIR)/rules.mk

PKG_NAME:=utf8decoder
PKG_VERSION:=2010-06-25

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)
PKG_SRC_DIR=$(abspath .)

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=utf8decoder_license.txt

include $(INCLUDE_DIR)/package.mk

define Package/utf8decoder
  SECTION:=utils
  CATEGORY:=Extra packages
  TITLE:=UTF8 Decoder Checker
  URL:=http://bjoern.hoehrmann.de/utf-8/decoder/dfa
  DEPENDS:=
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	echo "do_nothing:" > $(PKG_BUILD_DIR)/Makefile
endef

define Build/Compile
	echo "do_nothing:" > $(PKG_BUILD_DIR)/Makefile
endef

define Package/utf8decoder/install
	# at least one unique file needs to be copied so the license tool picks up this package
	$(INSTALL_DIR) $(1)/home/ipbridge/.dummy
	$(INSTALL_DATA) ./files/utf8decoder_dummy.txt $(1)/home/ipbridge/.dummy/utf8decoder_dummy.txt
endef

$(eval $(call BuildPackage,utf8decoder))

