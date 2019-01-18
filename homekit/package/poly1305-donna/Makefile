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

PKG_NAME:=poly1305-donna
PKG_VERSION:=1.0
PKG_RELEASE:=$(PKG_SOURCE_VERSION)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/floodyberry/poly1305-donna
PKG_SOURCE_SUBDIR:=${PKG_NAME}-${PKG_VERSION}
PKG_SOURCE_VERSION:=dabffc6608eaca87d48c4ce9fc33a1e74a47e3f9
PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=README.md

include $(INCLUDE_DIR)/package.mk

PKG_INSTALL:=1

define Package/poly1305-donna
  SECTION:=libs
  SUBMENU:=Crypto
  CATEGORY:=Libraries
  TITLE:=Library implementing the Poly1305-donna cipher
  URL:=http://cr.yp.to/mac.html
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/* $(1)/usr/include/

	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libpoly1305-donna.{so*,a} $(1)/usr/lib
endef

define Package/poly1305-donna/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libpoly1305-donna.so* $(1)/usr/lib
endef

$(eval $(call BuildPackage,poly1305-donna))
