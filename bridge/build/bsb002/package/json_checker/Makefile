# Copyright (C) 2017 Philips Lighting

include $(TOPDIR)/rules.mk

PKG_NAME:=json_checker
PKG_VERSION:=2007-08-24

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)
PKG_SRC_DIR=$(abspath .)

PKG_LICENSE:=JSON
PKG_LICENSE_FILES:=json_checker_license.txt

include $(INCLUDE_DIR)/package.mk

define Package/json_checker
  SECTION:=utils
  CATEGORY:=Extra packages
  TITLE:=JSON Checker
  URL:=http://www.json.org/JSON_checker/
  DEPENDS:=
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	echo "do_nothing:" > $(PKG_BUILD_DIR)/Makefile
endef

define Build/Compile
	echo "do_nothing:" > $(PKG_BUILD_DIR)/Makefile
endef

define Package/json_checker/install
	# at least one unique file needs to be copied so the license tool picks up this package
	$(INSTALL_DIR) $(1)/home/ipbridge/.dummy
	$(INSTALL_DATA) ./files/json_checker_dummy.txt $(1)/home/ipbridge/.dummy/json_checker_dummy.txt
endef

$(eval $(call BuildPackage,json_checker))

