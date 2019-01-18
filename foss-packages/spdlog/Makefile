# Copyright (C) 2017 Philips Lighting

include $(TOPDIR)/rules.mk

include config.mk

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/spdlog
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=spdlog library development headers
  DEPENDS:=+libpthread
endef

define Package/spdlog/description
  Fast logger header-only library
endef

define Build/Compile
	echo "do_nothing:" > $(PKG_BUILD_DIR)/Makefile
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/spdlog
	$(CP) $(PKG_BUILD_DIR)/include/spdlog/* $(1)/usr/include/spdlog/
endef

$(eval $(call BuildPackage,spdlog))
