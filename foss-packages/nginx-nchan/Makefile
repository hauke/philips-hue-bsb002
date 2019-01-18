# Copyright (C) 2017 Philips Lighting

include $(TOPDIR)/rules.mk

include config.mk

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENCE

include $(INCLUDE_DIR)/package.mk

define Package/nginx-nchan
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Nginx-nchan module
  DEPENDS:=+libpthread
endef

define Package/nginx-nchan/description
  Nchan is a module for the Nginx web server.
endef

define Build/Configure
	mkdir -p $(PKG_BUILD_DIR)
	$(Build/Configure/Default)
endef

define Build/Compile
	echo "do_nothing:" > $(PKG_BUILD_DIR)/Makefile
endef

define Build/InstallDev
	echo "do_nothing:" >> $(PKG_BUILD_DIR)/Makefile
endef

$(eval $(call BuildPackage,nginx-nchan))
