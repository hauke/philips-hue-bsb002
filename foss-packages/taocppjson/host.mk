TOP_DIR ?= $(abspath ../..)
INCLUDE_DIR := $(TOP_DIR)/include/make

include $(INCLUDE_DIR)/defaults.mk

include config.mk

QSDK_PKG_DIR=$(PKG_NAME)

REQUIRED_EXECUTABLES += \
  autoconf automake libtool curl make g++ unzip

include $(INCLUDE_DIR)/utils.mk
include $(INCLUDE_DIR)/buildReqs.mk
include $(INCLUDE_DIR)/dependencies.mk
include $(INCLUDE_DIR)/extract.mk
include $(INCLUDE_DIR)/package/packageDefs.mk
include $(INCLUDE_DIR)/package/deploy.mk
include $(INCLUDE_DIR)/package/clean.mk

configure.done:
	$(call stepinfo)
	@mkdir -p $(PKG_BUILD_DIR)
	@cd $(PKG_BUILD_DIR) && echo "Nothing to configure"
	$(done)

.PHONY : install
install: configure.done
	$(call stepinfo)
	@mkdir -p $(STAGING_DIR)
	@cp -a $(SET_STAGING_ENV) $(STAGING_DIR)
	@mkdir -p $(PREFIX_PATH)/include/tao/
	@cp -a $(PKG_BUILD_DIR)/include/tao/* $(PREFIX_PATH)/include/tao/
