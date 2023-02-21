################################################################################
#
# phytium-optee
#
################################################################################

PHYTIUM_OPTEE_SITE_METHOD = git
PHYTIUM_OPTEE_SITE = $(call qstrip,$(BR2_PACKAGE_PHYTIUM_OPTEE_CUSTOM_REPO_URL))
PHYTIUM_OPTEE_VERSION = $(call qstrip,$(BR2_PACKAGE_PHYTIUM_OPTEE_CUSTOM_REPO_VERSION))

PHTYIUM_OPTEE_TARGET_BOARD = $(call qstrip,$(BR2_PACKAGE_PHYTIUM_OPTEE_BOARD))

# install optee os/client sdk in staging
# if other package need build CA & TA, CA will use default staging path.
# TA need set TA_DEV_KIT_DIR=$(PHYTIUM_OPTEE_OS_SDK).
PHYTIUM_OPTEE_OS_SDK = $(STAGING_DIR)/lib/optee/export-ta_arm64
PHYTIUM_OPTEE_CLIENT_SDK = $(STAGING_DIR)/usr

# build optee os need this package in host
PHYTIUM_OPTEE_DEPENDENCIES = host-openssl host-python3 host-python-pycryptodomex host-python-pyelftools

PHYTIUM_OPTEE_INSTALL_IMAGES = YES
PHYTIUM_OPTEE_INSTALL_STAGING = YES

define PHYTIUM_OPTEE_BUILD_CMDS
	cd $(@D); ./build_all clean; CROSS_COMPILE64=$(TARGET_CROSS) ./build_all $(PHTYIUM_OPTEE_TARGET_BOARD) d
endef

# install lib & ta & client into rootfs
define PHYTIUM_OPTEE_INSTALL_TARGET_CMDS
	cp -dpf $(@D)/out/data/bin/* $(TARGET_DIR)/usr/bin
	cp -dpf $(@D)/out/data/lib/* $(TARGET_DIR)/usr/lib
	mkdir -p $(TARGET_DIR)/data/optee_armtz
	cp $(@D)/out/data/optee_armtz/* $(TARGET_DIR)/data/optee_armtz
endef

# install tee.bin into BINARIES_DIR, so that can use tboot to load tee os.
define PHYTIUM_OPTEE_INSTALL_IMAGES_CMDS
	cp -dpf $(@D)/out/*.bin $(BINARIES_DIR)
endef

# install sdk for build other package
define PHYTIUM_OPTEE_INSTALL_STAGING_CMDS
	#echo $(STAGING_DIR)
	mkdir -p $(PHYTIUM_OPTEE_OS_SDK)
	cp -ardpf $(@D)/out/data/link/export/usr/* $(PHYTIUM_OPTEE_CLIENT_SDK)
endef


define PHYTIUM_OPTEE_INSTALL_INIT_SYSV
	$(INSTALL) -m 0755 -D $(PHYTIUM_OPTEE_PKGDIR)/S30phytium-optee \
		$(TARGET_DIR)/etc/init.d/S30phytium-optee
endef

$(eval $(generic-package))
