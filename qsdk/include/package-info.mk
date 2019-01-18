define add_package_info
	( \
		echo "Package: $(PKG_NAME)"; \
		echo "Version: $(PKG_VERSION)"; \
		DEPENDS='$(EXTRA_DEPENDS)'; \
		for depend in $$(filter-out @%,$(call filter_deps,$(call PKG_FIXUP_DEPENDS,$(PKG_NAME),$(DEPENDS)))); do \
			DEPENDS=$$$${DEPENDS:+$$$$DEPENDS, }$$$${depend##+}; \
		done; \
		[ -z "$$$$DEPENDS" ] || echo "Depends: $$$$DEPENDS"; \
		BUILD_DEPENDS=''; \
		for depend in $$(filter-out @%,$(call filter_deps,$(call PKG_FIXUP_DEPENDS,$(PKG_NAME),$(PKG_BUILD_DEPENDS)))); do \
			BUILD_DEPENDS=$$$${BUILD_DEPENDS:+$$$$BUILD_DEPENDS, }$$$${depend##+}; \
		done; \
		[ -z "$$$$BUILD_DEPENDS" ] || echo "BuildDepends: $$$$BUILD_DEPENDS"; \
		BUILD_DEPENDS_NOT_LINKED=''; \
		for depend in $(PKG_BUILD_DEPENDS_NOT_LINKED); do \
			BUILD_DEPENDS_NOT_LINKED=$$$${BUILD_DEPENDS_NOT_LINKED:+$$$$BUILD_DEPENDS_NOT_LINKED, }$$$${depend##+}; \
		done; \
		[ -z "$$$$BUILD_DEPENDS_NOT_LINKED" ] || echo "BuildDependsNotLinked: $$$$BUILD_DEPENDS_NOT_LINKED"; \
		echo "Source: $(patsubst $(TOPDIR)/%,%,$(CURDIR))"; \
		echo "Url: $$(PKG_URL)"; \
		echo "LocalSource: $$(LOCAL_SRC)"; \
		echo "PkgSource: $$(if $$(PKG_SOURCE),$$(PKG_SOURCE),$$(LINUX_SOURCE))"; \
		echo "PkgSourceUrls: $$(if $$(PKG_SOURCE_URL),$$(PKG_SOURCE_URL),$$(LINUX_SITE))"; \
		$$(if $$(PKG_DOWNLOADS),echo "PkgDownloads: $$(PKG_DOWNLOADS)"; ) \
		$$(if $$(PKG_DOWNLOAD_URLS),echo "PkgDownloadUrls: $$(PKG_DOWNLOAD_URLS)"; ) \
		$$(if $$(PKG_LICENSE), echo "License: $$(PKG_LICENSE)"; ) \
		$$(if $$(PKG_LICENSE_FILES), echo "LicenseFiles: $$(PKG_LICENSE_FILES)"; ) \
		echo "Section: $(SECTION)"; \
		$(if $(filter hold,$(PKG_FLAGS)),echo "Status: unknown hold not-installed"; ) \
		$(if $(filter essential,$(PKG_FLAGS)), echo "Essential: yes"; ) \
		$(if $(MAINTAINER),echo "Maintainer: $(MAINTAINER)"; ) \
		echo "Architecture: $(PKGARCH)"; \
		echo -n "Description: "; $(SH_FUNC) getvar $(call shvar,Package/$(1)/description) | sed -e 's,^[[:space:]]*, ,g'; \
		if [ -n "$$$$ATTRIBUTIONS" ]; then \
			printf "Attributions: "; echo "$$$$ATTRIBUTIONS" | sed -e 's,^[[:space:]]*, ,g'; \
		fi;  \
	) > $(1)/.pkg-info;
endef

define add_target_package_info
	$(call add_package_info,$(PKG_BUILD_DIR))
endef

define add_host_package_info
	$(call add_package_info,$(HOST_BUILD_DIR))
endef

Hooks/HostPrepare/Post += add_host_package_info
Hooks/Prepare/Post += add_target_package_info
