.DEFAULT_GOAL      := factoryImages
BUILD              :=product
product            :=bsb002
PRODUCT            :=BSB002
TOP_DIR            :=$(abspath .)
PRODUCT_MAKE_DIR   :=bridge/build/bsb002
RELEASE_FACTORY_DIR:=bridge/build/bsb002/release/product/factory/bsb002

define printInColor
	echo -n "\033[$(1)m$(2)\033[0m\n"
endef

RED=31
YELLOW=33
STEP_INFO_COLOR=$(RED)

define stepinfo
	@$(call printInColor,$(STEP_INFO_COLOR),Making $@)
endef

define createBuildLogDir
	if ! test -d "$(BUILD_LOG_DIR)"; then \
		$(call printInColor,$(YELLOW),Creating $(BUILD_LOG_DIR)); \
		mkdir -p $(BUILD_LOG_DIR); \
	fi
endef

# Definitions
PRODUCT_BUILD=product
DEVELOP_BUILD=develop

# Platform configuration options
QSDK_DIR                 ?=$(TOP_DIR)/qsdk
BUILD                    ?=$(DEVELOP_BUILD)
PRODUCT_MAKE_DIR         ?=$(abspath .)
TOP_BUILD_DIR            ?=$(PRODUCT_MAKE_DIR)/build_dir
RELEASE_DIR              ?=$(PRODUCT_MAKE_DIR)/release
CONFIGS_DIR              ?=$(PRODUCT_MAKE_DIR)/configs
export BUILD

$(info $(shell $(call printInColor,$(YELLOW),Using BUILD=$(BUILD))))

# Tools required by this makefile
MKDIR=mkdir
BUILD_DIR=$(TOP_BUILD_DIR)/$(BUILD)
BUILD_LOG_DIR=$(BUILD_DIR)/build-logs
QSDK_FEEDS_DIR=$(QSDK_DIR)/feeds
QSDK_FEEDS_PACKAGE_MAKEFILES=$(shell find $(QSDK_FEEDS_DIR)/*/ -name Makefile 2>/dev/null | sort -u)
QSDK_SCRIPTS_DIR=$(QSDK_DIR)/scripts
QSDK_CONFIG_DEST=$(QSDK_DIR)/.config
QSDK_BUILD_DIR=$(QSDK_DIR)/build_dir
QSDK_LOGS_DIR=$(QSDK_DIR)/logs
QSDK_PLATFORM=ar71xx
QSDK_BIN_DIR=$(QSDK_DIR)/bin/$(QSDK_PLATFORM)
QSDK_MIPS_BUILD_DIR=$(QSDK_BUILD_DIR)/target-mips_*_uClibc-*
QSDK_CONFIG_FILE=bridge/build/bsb002/configs/qsdk.product.config
QSDK_LAST_WRITTEN_LOG_FILE=`find $(QSDK_LOGS_DIR)/ -type f -printf '%T@ %p\n' | sort -n | tail -1 | awk '{print $$2}'`
ASSEMBLED_FEEDS_CONF=$(TOP_BUILD_DIR)/feeds.conf

ifndef SKIP_QSDK_BUILD
QSDK_BUILT_DEPS=$(MANIFEST_HEAD) qsdk.built
endif

# Images needed by the factory
FACTORY_IMAGES=\
  $(product)_uboot.bin \
  kernel.bin \
  root.bin \
  overlay.bin

# QSDK-build generated source locations
QSDK_BIN_BASE=$(QSDK_BIN_DIR)/openwrt-$(QSDK_PLATFORM)
BIN_SOURCE_$(product)_uboot=$(QSDK_BIN_BASE)-$(product)-qca-legacy-uboot.bin
BIN_SOURCE_kernel=$(QSDK_BIN_BASE)-generic-uImage-lzma.bin
BIN_SOURCE_root=$(QSDK_BIN_BASE)-generic-$(product)-root-squashfs.ubi
BIN_SOURCE_overlay=$(QSDK_BIN_BASE)-generic-$(product)-overlay-jffs2.ubi

# Make the dependency clear for QSDK-build generated source locations
$(BIN_SOURCE_$(product)_uboot) $(BIN_SOURCE_kernel) $(BIN_SOURCE_root) $(BIN_SOURCE_overlay): $(QSDK_BUILT_DEPS)

# Make sure that qsdk.* stamp files are placed in the state directory
vpath qsdk.% $(TOP_BUILD_DIR)

# Marks a build step complete by making a stamp file in the state directory
define done
	@$(MKDIR) -p $(TOP_BUILD_DIR)
	@touch $(TOP_BUILD_DIR)/$@
	@$(call printInColor,$(STEP_INFO_COLOR),Done: $@)
endef

# Hides the output in a log file, but shows the output if an error occurs
ifneq "$(V)" "s"
CURRENT_LOG_FILE=$(BUILD_LOG_DIR)/$(subst /,_,$@)
quietUnlessErrorsOrVerbose=>$(CURRENT_LOG_FILE) 2>&1 || (cat $(CURRENT_LOG_FILE); exit 1)
endif

FIRST_QSDK_BUILD_LOG_WITH_FAILURES=`find $(QSDK_LOGS_DIR)/ -type f | xargs egrep -l '( Error [0-9]+$$|: error:|^Traceback )' | xargs --no-run-if-empty ls -tr | awk '{print $$1}'`

ifneq "$(V)" "s"
define dumpBuildLogsWithErrors
|| ( \
  FIRST_ERROR_LOG="$(FIRST_QSDK_BUILD_LOG_WITH_FAILURES)"; \
  if [ -n "$${FIRST_ERROR_LOG}" ]; then \
    $(call printInColor,$(YELLOW),\
      \n============================================================================\
      \nThe first log that indicates a build failure is:\
      \n  $${FIRST_ERROR_LOG}\
      \n----------------------------------------------------------------------------\
    ); cat $${FIRST_ERROR_LOG}; $(call printInColor,$(YELLOW),\
      \n============================================================================\
      \n\
    ); \
  else \
    $(call printInColor,$(YELLOW),\
    \n============================================================================\
    \nMiscellaneous build failure:\
    \n  Re-run the build with V=s \
    \n============================================================================\
    \n\
    ); \
  fi; \
  exit 1 )
endef
endif



$(BUILD_LOG_DIR):
	@$(call createBuildLogDir)

# Copies an image bin to the release directory
#   %.bin is taken as the destination name
#   BIN_SOURCE_% must be defined to specify the source path
.SECONDEXPANSION:
.PRECIOUS : $(RELEASE_FACTORY_DIR)/%.bin
$(RELEASE_FACTORY_DIR)/%.bin: $$(BIN_SOURCE_$$(notdir $$*))
	$(call stepinfo)
	@$(MKDIR) -p $(@D)
	@cp $< $@

# Generates the factory images in the release directory
.PHONY : factoryImages
factoryImages: $(foreach image,$(FACTORY_IMAGES),$(RELEASE_FACTORY_DIR)/$(image))
	$(call stepinfo)




define syncQsdkConfig
	@$(call printInColor,$(STEP_INFO_COLOR),Using $(QSDK_CONFIG_FILE))
	@cp -a $(QSDK_CONFIG_FILE) $(QSDK_CONFIG_DEST)
	@$(MAKE) -C $(QSDK_DIR) defconfig $(call quietUnlessErrorsOrVerbose)
endef

define qsdkMake
	$(call syncQsdkConfig)
	@$(call printInColor,$(STEP_INFO_COLOR),Within $(QSDK_DIR): make $(1) (for $@))
	+$(2)@$(MAKE) --no-print-directory -C $(QSDK_DIR) $(1) 
endef

.PHONY : qsdk.assert-download-cache-up-to-date
qsdk.assert-download-cache-up-to-date:

.PHONY : qsdk.warn-on-src-tree-overrides
qsdk.warn-on-src-tree-overrides:

$(shell $(MKDIR) -p $(QSDK_BUILD_DIR))

# Monitor a variable for value changes
# $(1) name of the variable
monitorVariableForChanges=\
$(if \
  $(shell \
    ( \
      ( \
        echo '$($(1))' | cmp -s - $(QSDK_BUILD_DIR)/value-of-$1 \
      ) || ( \
        mv $(QSDK_BUILD_DIR)/value-of-$1 $(QSDK_BUILD_DIR)/value-of-$1.prev 2>/dev/null; \
        echo '$($(1))' > $(QSDK_BUILD_DIR)/value-of-$1; \
        echo 'print-something-to-satisfy-if' \
      ) \
    ) \
  ), \
  $(info $1 changed) \
)

$(call monitorVariableForChanges,ALL_FEEDS_CONF)
$(call monitorVariableForChanges,QSDK_FEEDS_PACKAGE_MAKEFILES)

vpath value-of-% $(QSDK_BUILD_DIR)
value-of-%:
	@[ -f $(QSDK_BUILD_DIR)/$@ ] || (echo 'error: to depend on $@, you need to add "$$(call monitorVariableForChanges,$*)" to the Makefile' >&2; exit 1)

QSDK_FEEDS_TOOL=\
  $(QSDK_SCRIPTS_DIR)/feeds \
  -F $(abspath $(ASSEMBLED_FEEDS_CONF))

# Update the QSDK feeds
qsdk.feeds-updated: $(BUILD_LOG_DIR) $(ASSEMBLED_FEEDS_CONF) $(QSDK_FEEDS_PACKAGE_MAKEFILES) value-of-QSDK_FEEDS_PACKAGE_MAKEFILES
	$(call stepinfo)
	@(cd $(QSDK_DIR) && $(QSDK_FEEDS_TOOL) clean -a) $(call quietUnlessErrorsOrVerbose)
	@(cd $(QSDK_DIR) && $(QSDK_FEEDS_TOOL) update -a) $(call quietUnlessErrorsOrVerbose)
	@(cd $(QSDK_DIR) && $(QSDK_FEEDS_TOOL) install -a -f) $(call quietUnlessErrorsOrVerbose)
	$(call done)

.PHONY : qsdk.clean-changed-packages
qsdk.clean-changed-packages:

# Compile the QSDK
.PHONY : qsdk.built
qsdk.built: assert-build-requirements qsdk.feeds-updated qsdk.clean-changed-packages qsdk/world qsdk.assert-download-cache-up-to-date qsdk.warn-on-src-tree-overrides
	$(call stepinfo)
	$(call updateLastBuiltCommits)

# Execute a QSDK make rule
.PHONY : qsdk/% 
qsdk/%: assert-build-requirements qsdk.feeds-updated
	$(call stepinfo)
	$(call qsdkMake,$*) $(dumpBuildLogsWithErrors)

# Purges a local make step so that the step will be redone on the next build
.PHONY : qsdk.%/purge 
qsdk.%/purge: assert-build-requirements
	$(call stepinfo)
	@rm -f $(TOP_BUILD_DIR)/qsdk.$*
	@echo step.$* purged

# Forcefully rebuild the run-once rule
.PHONY : qsdk.%/force
qsdk.%/force: assert-build-requirements
	$(call stepinfo)
	@$(MAKE) qsdk.$*

# Helper to print internal make variables
.PHONY : print-%
print-%:
	@echo '$*=$($*)'

.PHONY:
assert-build-requirements:
	$(call stepinfo)
