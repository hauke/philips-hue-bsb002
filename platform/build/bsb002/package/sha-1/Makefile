# Copyright (C) 2017 Philips Lighting

include $(TOPDIR)/rules.mk

PKG_NAME:=sha-1
PKG_VERSION:=unknown

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)
PKG_SRC_DIR=$(abspath .)

PKG_LICENSE:=FPL
PKG_LICENSE_FILES:=sha_1_license.txt

include $(INCLUDE_DIR)/package.mk

define Package/sha-1
  SECTION:=utils
  CATEGORY:=Extra packages
  TITLE:=SHA-1
  URL:=http://www.packetizer.com/security/sha1/
  DEPENDS:=
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	echo "do_nothing:" > $(PKG_BUILD_DIR)/Makefile
endef

define Build/Compile
	echo "do_nothing:" > $(PKG_BUILD_DIR)/Makefile
endef

define Package/sha-1/install
	# at least one unique file needs to be copied so the license tool picks up this package
	$(INSTALL_DIR) $(1)/home/ipbridge/.dummy
	$(INSTALL_DATA) ./files/sha_1_dummy.txt $(1)/home/ipbridge/.dummy/sha_1_dummy.txt
endef

$(eval $(call BuildPackage,sha-1))

