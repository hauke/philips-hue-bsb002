# Copyright (C) 2017 Philips Lighting

include $(TOPDIR)/rules.mk

include config.mk

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/taocppjson
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=C++11 header-only json library
  DEPENDS:=+libpthread
endef

define Package/taocppjson/description
  C++11 header-only library that provides a generic JSON Value object
endef

define Build/Compile
	echo "do_nothing:" > $(PKG_BUILD_DIR)/Makefile
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/tao
	$(CP) $(PKG_BUILD_DIR)/include/tao/* $(1)/usr/include/tao/
endef

$(eval $(call BuildPackage,taocppjson))
