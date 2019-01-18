TOP_DIR ?= $(abspath ../..)
INCLUDE_DIR := $(TOP_DIR)/include/make

include $(INCLUDE_DIR)/defaults.mk

include config.mk

QSDK_PKG_DIR=$(PKG_NAME)

REQUIRED_EXECUTABLES += \
  autoconf automake libtool curl make g++ unzip

PACKAGE_DEPS := nginx

NGINX_NCHAN_CONFIGURE_OPTIONS:=\
  --with-http_ssl_module \
  --with-compat \
  --add-dynamic-module=$(BUILD_DIR)/nginx-nchan \
  --with-cc-opt="-I$(PREFIX_PATH)/include $(CFLAGS)" \
  --with-ld-opt="-L$(PREFIX_PATH)/lib"

include $(INCLUDE_DIR)/utils.mk
include $(INCLUDE_DIR)/buildReqs.mk
include $(INCLUDE_DIR)/dependencies.mk
include $(INCLUDE_DIR)/extract.mk
include $(INCLUDE_DIR)/package/packageDefs.mk
include $(INCLUDE_DIR)/package/deploy.mk
include $(INCLUDE_DIR)/package/clean.mk

PKG_NGINX_VERSION=nginx*

configure.done:
	$(call stepinfo)
	@mkdir -p $(PKG_BUILD_DIR)
	(cd $(PKG_MAKEDIR_nginx)/build_dir/$(BUILD)/$(PKG_NGINX_VERSION) && ./configure $(NGINX_NCHAN_CONFIGURE_OPTIONS))
	(cd $(PKG_MAKEDIR_nginx)/build_dir/$(BUILD)/$(PKG_NGINX_VERSION) && $(MAKE) modules)
	$(done)

.PHONY : install
install: configure.done
	$(call stepinfo)
	@mkdir -p $(STAGING_DIR)/usr/local/nginx/modules
	@cp $(PKG_MAKEDIR_nginx)/build_dir/$(BUILD)/$(PKG_NGINX_VERSION)/objs/ngx_nchan_module.so $(STAGING_DIR)/usr/local/nginx/modules
	$(done)
