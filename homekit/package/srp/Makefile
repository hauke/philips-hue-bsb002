#
# CA Engineering OpenWrt/QSDK Crypto libraries
#
# Copyright 2013-2015 Card Access Engineering, LLC
#
# This software is the confidential and proprietary information of Card Access
# Engineering, LLC (“CAE”).  
#
# If this software is made available to you pursuant to the terms of a
# separate license agreement issued by CAE (the “License Agreement”), your
# right to use, copy, modify, make derivative works of and/or distribute this
# software is limited, as specifically set forth in the License Agreement, and
# all disclaimers and limitations set forth in the License Agreement apply to
# this software.
#
# If this software is made available to you without a separate license
# agreement, then the following provisions apply:
#
# 1. CAE hereby grants to you a limited, revocable, nonexclusive,
# nonassignable and nontransferable license to use this software until
# otherwise notified by CAE for the sole purpose of evaluating the software.
# You may not copy, duplicate, reproduce or distribute the software in any
# manner without the prior consent of CAE, which CAE may grant or withhold in
# its sole discretion.  You further agree that you will not reverse engineer
# or decompile the software or take any action (other than as an ordinary end
# user) that is designed to provide you information relating to the algorithms
# or data sets used in or the structure of the software.
#
# 2. THE SOFTWARE IS PROVIDED "AS IS" AND CAE DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT WILL CAE BE LIABLE FOR ANY
# SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
# OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE. 
#

include $(TOPDIR)/rules.mk

PKG_NAME:=srp
PKG_VERSION:=2.1.2
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://srp.stanford.edu/source
PKG_MD5SUM:=39d150d2fcfcea1646c405172b748119

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=docs/LICENSE

PKG_CONFIG_DEPENDS:=\
	SRP_TOMMATH \
	SRP_TOMCRYPT \
	SRP_SHA1

include $(INCLUDE_DIR)/package.mk

PKG_INSTALL:=1

define Package/srp
  SECTION:=libs
  SUBMENU:=Crypto
  CATEGORY:=Libraries
  TITLE:=Library implementing the SRP routines
  URL:=http://srp.stanford.edu/
  DEPENDS:=+libc +SRP_TOMMATH:tommath +SRP_TOMCRYPT:tomcrypt
  MENU:=1
endef

define Package/srp/config
source "$(SOURCE)/Config.in"
endef

define Package/srp/attributions
  This product includes software developed by the University of California, Berkeley and its contributors.
  This product includes cryptographic software written by Eric Young (eay@mincom.oz.au)  
  This product includes software written by Tim Hudson (tjh@mincom.oz.au) 
endef

# Specify SHA1 if enabled
TARGET_CFLAGS += $(FPIC) \
	$(if $(CONFIG_SRP_SHA1),-DSHA1)

# Specify library dependencies when linking this library
TARGET_LDFLAGS += \
	$(if $(CONFIG_SRP_TOMMATH),-ltommath) \
	$(if $(CONFIG_SRP_TOMCRYPT),-ltomcrypt) \
	$(if $(CONFIG_TOMCRYPT_TOMMATH),-ltommath) \
	$(if $(CONFIG_TOMCRYPT_TOMSFASTMATH),-ltomsfastmath)

# Add configure arguments according to which library libsrp should use
CONFIGURE_ARGS +=\
	$(if $(CONFIG_SRP_TOMMATH),--with-tommath="$(STAGING_DIR)/usr") \
	$(if $(CONFIG_SRP_TOMCRYPT),--with-tomcrypt="$(STAGING_DIR)/usr")

# Only configure the libsrp directory
CONFIGURE_PATH=libsrp

# Only compile and install the libsrp subdirectory
MAKE_PATH=libsrp

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/* $(1)/usr/include/

	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libsrp.{so*,a} $(1)/usr/lib
endef

define Package/srp/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libsrp.so* $(1)/usr/lib
endef

$(eval $(call BuildPackage,srp))
