include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/version.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=lk-af
PKG_SOURCE_PROTO:=git
PKG_BRANCH:=master
PKG_RELEASE:=1
include $(INCLUDE_DIR)/local-development.mk

PKG_SOURCE_VERSION:=$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/lk-ipq806x
  SECTION:=boot
  CATEGORY:=Boot Loaders
  DEPENDS:=@TARGET_ipq806x
  TITLE:=lk bootloader for IPQ806x based platforms
  URL:=
endef

define Build/Compile
	VERSION_CODE='$(VERSION_NICK) $(VERSION_NUMBER)' \
	REVISION='$(REVISION)' \
	$(MAKE) -C $(PKG_BUILD_DIR) HOSTCC=$(TARGET_CC) \
		ARCH="$(LINUX_KARCH)" QSDK_CFLAGS="$(TARGET_CFLAGS)" \
		QSDK_LDFLAGS="$(TARGET_LDFLAGS)" PROJECT=ipq806x \
		TOOLCHAIN_PREFIX="$(TARGET_CROSS)"
endef

define Package/lk-ipq806x/install
	$(INSTALL_DIR) $(1)
	$(CP) $(PKG_BUILD_DIR)/build-ipq806x/appsboot.mbn $(BIN_DIR)/openwrt-$(BOARD)-lkboot.mbn
	$(CP) $(PKG_BUILD_DIR)/build-ipq806x/appsboot.raw $(BIN_DIR)/openwrt-$(BOARD)-lkboot.raw
endef

$(eval $(call BuildPackage,lk-ipq806x))
