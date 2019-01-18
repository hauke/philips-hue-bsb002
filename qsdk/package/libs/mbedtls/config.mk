# Extracted from OpenWRT Makefile so that the version information can be used
# for consistent ubuntu builds
PKG_NAME:=mbedtls
PKG_VERSION:=2.3.0
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-apache.tgz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

PKG_SOURCE_URL:=https://tls.mbed.org/download/
PKG_MD5SUM:=4dab982481441ed0a0235bc06d40eb17

CMAKE_OPTIONS += \
	-DCMAKE_BUILD_TYPE:String="Release" \
	-DUSE_SHARED_MBEDTLS_LIBRARY:Bool=ON \
	-DUSE_STATIC_MBEDTLS_LIBRARY:Bool=OFF
