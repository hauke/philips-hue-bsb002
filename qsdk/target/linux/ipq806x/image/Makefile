# Copyright (c) 2014 The Linux Foundation. All rights reserved.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

UBIFS_OPTS = -m 2048 -e 124KiB -c 4096 -U -F
UBI_OPTS = -m 2048 -p 128KiB

E2SIZE=$(shell echo $$(($(CONFIG_TARGET_ROOTFS_PARTSIZE)*1024)))

ifeq ($(strip $(call CompareKernelPatchVer,$(KERNEL_PATCHVER),eq,3.18)),1)
IPQ806X_KERNEL_LOADADDR = 0x42008000
IPQ40XX_KERNEL_LOADADDR = 0x80008000
else
IPQ806X_KERNEL_LOADADDR = 0x42208000
IPQ40XX_KERNEL_LOADADDR = 0x80208000
endif
IPQ807X_KERNEL_LOADADDR = 0x41208000

ifneq ($(CONFIG_TARGET_ROOTFS_UBIFS),)
define Image/mkfs/ubifs_fit
	$(call Image/ubifs_128MB,$(1))
	$(call Image/ubifs_512MB,$(1))
	$(call Image/UbiImage,$(1))
endef
endif

define Image/BuildKernel/FIT
	$(CP) $(KDIR)/Image $(BIN_DIR)/$(IMG_PREFIX)-vmlinux.bin
	gzip -9 -c $(KDIR)/Image > $(KDIR)/Image.gz
	$(call CompressLzma,$(KDIR)/Image,$(KDIR)/Image.gz)
	$(call Image/BuildKernel/MkFIT,$(1), $(KDIR)/Image.gz, $(LINUX_DIR)/arch/arm/boot/dts/$(1).dtb,gzip,$(2),$(2))
	$(CP) $(KDIR)/fit-$(1).itb $(BIN_DIR)/$(IMG_PREFIX)-$(1)-fit-uImage.itb
	$(CP) $(LINUX_DIR)/arch/arm/boot/dts/$(1).dtb $(BIN_DIR)/$(IMG_PREFIX)-$(1).dtb
	mkdir -p $(BIN_DIR)/dtbs/
	$(CP) $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq80*.dtb $(BIN_DIR)/dtbs/
	$(CP) $(LINUX_DIR)/arch/arm/boot/Image $(BIN_DIR)/dtbs/
endef

define Image/BuildKernel/FITInitramfs
	$(CP) $(KDIR)/Image-initramfs $(BIN_DIR)/$(IMG_PREFIX)-vmlinux-initramfs.bin
	$(call Image/BuildKernel/MkFIT,$(1), $(KDIR)/Image-initramfs, $(LINUX_DIR)/arch/arm/boot/dts/$(1).dtb, none,$(2),$(2))
	$(CP) $(KDIR)/fit-$(1).itb $(BIN_DIR)/$(IMG_PREFIX)-$(1)-fit-uImage-initramfs.itb
endef

define Image/Prepare
	$(CP) $(LINUX_DIR)/vmlinux $(KDIR)/$(IMG_PREFIX)-vmlinux.elf
endef

define Image/BuildKernel/GenericFIT
	$(CP) $(KDIR)/Image $(BIN_DIR)/$(IMG_PREFIX)-vmlinux.bin
	gzip -9 -c $(KDIR)/Image > $(KDIR)/Image.gz
	$(call CompressLzma,$(KDIR)/Image,$(KDIR)/Image.gz)
	$(call Image/BuildKernel/MkFIT,$(1), $(KDIR)/Image.gz,,gzip,$(2),$(2))
	$(CP) $(KDIR)/fit-$(1).itb $(BIN_DIR)/$(IMG_PREFIX)-$(1)-fit-uImage.itb
endef

define Image/BuildKernel/MultiDTBFIT
	$(CP) $(KDIR)/Image $(BIN_DIR)/$(IMG_PREFIX)-vmlinux.bin
	gzip -9 -c $(KDIR)/Image > $(KDIR)/Image.gz
	$(call CompressLzma,$(KDIR)/Image,$(KDIR)/Image.gz)
	$(call Image/BuildKernel/MkFITMulti,$(1),$(KDIR)/Image.gz,$(2),gzip,$(3),$(3))
	$(CP) $(KDIR)/fit-$(1).itb $(BIN_DIR)/$(IMG_PREFIX)-$(1)-fit-uImage.itb
endef

# some tree's don't have all the device tree's so we filter out
# the ones that are not present
# $(1) is the filter to apply
FindDeviceTrees ?= $(notdir $(basename $(shell find $(LINUX_DIR)/arch/arm/boot/dts/ -name $(1)*.dts $(2) 2>/dev/null)))

define Image/BuildKernel/template
	$(CP) $(KDIR)/vmlinux$(subst openwrt-ipq806x,,$(IMG_PREFIX)).debug $(BIN_DIR)/$(IMG_PREFIX)-vmlinux.elf

	$(foreach device, $(call FindDeviceTrees, qcom-ipq8064-), \
		$(call Image/BuildKernel/$(1),$(device),$(IPQ806X_KERNEL_LOADADDR));)

	$(foreach device, $(call FindDeviceTrees, qcom-ipq40??-), \
		$(call Image/BuildKernel/$(1),$(device),$(IPQ40XX_KERNEL_LOADADDR));)

	$(foreach device, $(call FindDeviceTrees, qcom-ipq807x-), \
		$(call Image/BuildKernel/$(1),$(device),$(IPQ807X_KERNEL_LOADADDR));)
endef

define Image/BuildKernel
	$(call Image/BuildKernel/template,FIT)

	$(call Image/BuildKernel/GenericFIT,qcom-ipq40xx,$(IPQ40XX_KERNEL_LOADADDR))
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq40xx-ap.dkxx, \
		$(call FindDeviceTrees, qcom-ipq40??-ap) $(call FindDeviceTrees, qcom-ipq40??-db), \
		$(IPQ40XX_KERNEL_LOADADDR))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-ap148_1xx.dtb), \
		$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-ap148_1xx, \
		$(call FindDeviceTrees, qcom-ipq8064-*ap148_1xx), \
		$(IPQ806X_KERNEL_LOADADDR)))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-ap148.dtb), \
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-ap148, \
		$(call FindDeviceTrees, qcom-ipq8064-*ap148,-not -name *ap148_1xx* -not -name *ap148-nand*), \
		$(IPQ806X_KERNEL_LOADADDR)))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-db149.dtb), \
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-db149, \
		$(call FindDeviceTrees, qcom-ipq8064-*db149), \
		$(IPQ806X_KERNEL_LOADADDR)))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-ak01.dtb), \
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-ak01, \
		$(call FindDeviceTrees, qcom-ipq8064-*ak01), \
		$(IPQ806X_KERNEL_LOADADDR)))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-ap145_1xx.dtb), \
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-ap145_1xx, \
		$(call FindDeviceTrees, qcom-ipq8064-*ap145_1xx), \
		$(IPQ806X_KERNEL_LOADADDR)))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-ap145.dtb), \
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-ap145, \
		$(call FindDeviceTrees, qcom-ipq8064-*ap145,-not -name *ap145_1xx*), \
		$(IPQ806X_KERNEL_LOADADDR)))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-ap160_2xx.dtb), \
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-ap160_2xx, \
		$(call FindDeviceTrees, qcom-ipq8064-*ap160_2xx), \
		$(IPQ806X_KERNEL_LOADADDR)))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-ap160.dtb), \
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-ap160, \
		$(call FindDeviceTrees, qcom-ipq8064-*ap160,-not -name *ap160_2xx*), \
		$(IPQ806X_KERNEL_LOADADDR)))
	$(if $(wildcard $(LINUX_DIR)/arch/arm/boot/dts/qcom-ipq8064-ap161.dtb), \
	$(call Image/BuildKernel/MultiDTBFIT,qcom-ipq8064-ap161, \
		$(call FindDeviceTrees, qcom-ipq8064-*ap161), \
		$(IPQ806X_KERNEL_LOADADDR)))
endef

define Image/BuildKernel/Initramfs
	$(call Image/BuildKernel/template,FITInitramfs)
endef

UBI_IMAGES=qcom-ipq8064-db149 \
	qcom-ipq8064-ap148 \
	qcom-ipq8064-ak01 \
	qcom-ipq8064-ap145_1xx \
	qcom-ipq8064-ap145 \
	qcom-ipq8064-ap160 \
	qcom-ipq8064-ap161 \
	qcom-ipq8064-ap160_2xx

define Image/UbiPrepare
	$(if $(wildcard $(DTS_DIR)/$(1).dtb), \
	$(call Image/Build/UbinizeImage,$(1),$(BIN_DIR)/$(IMG_PREFIX)-$(1)-fit-uImage.itb,$(2),$(3),$(4));)
endef

define Image/UbiImage

ifeq ($(1),-ipq806x)
	$(eval UBI_OPTS:="-m 2048 -p 128KiB")
	$(foreach image,$(UBI_IMAGES), \
	$(call Image/UbiPrepare,$(image),squashfs,"ubi_rootfs","rootfs_data"))
	$(call Image/UbiPrepare,qcom-ipq8064-ap148-nand,squashfs,"rootfs","rootfs_data")
endif
endef

define Image/ubifs_512MB

  ifeq ($(1),-ipq40xx)
	$(eval UBI_OPTS:="-m 4096 -p 256KiB")
	$(call Image/mkfs/ubifs/generate,$(1))
	$(call Image/Build,ubi,$(1),-512MB)
  endif
endef

define Image/ubifs_128MB
	$(eval UBI_OPTS:="-m 2048 -p 128KiB")
	$(call Image/mkfs/ubifs/generate,$(1))
	$(call Image/Build,ubi,$(1))
endef

define Image/Build/squashfs
	$(call prepare_generic_squashfs,$(KDIR)/root.squashfs)
endef

define Image/Build
	$(call Image/Build/$(1),$(1))
	dd if=$(KDIR)/root$(2).$(1) of=$(BIN_DIR)/$(IMG_PREFIX)$(2)-$(1)-root$(3).img bs=2k conv=sync
endef

$(eval $(call BuildImage))
