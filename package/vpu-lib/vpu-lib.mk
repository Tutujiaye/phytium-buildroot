################################################################################
#
# vpu lib
#
################################################################################

VPU_LIB_VERSION = 28655c1d76a99db4460a3bc85e766555d568ecee
VPU_LIB_SITE = https://gitee.com/phytium_embedded/vpu-lib.git
VPU_LIB_INSTALL_TARGET = YES
VPU_LIB_SITE_METHOD = git
VPU_LIB_DEPENDENCIES = linux

ifeq ($(BR2_PACKAGE_VPU_LIB_FIRMWARE),y)
define VPU_LIB_INSTALL_TARGET_CMDS
	cp -a $(@D)/$(BR2_PACKAGE_VPU_LIB_CPU_MODEL)/lib/firmware $(TARGET_DIR)/lib
endef
else
define VPU_LIB_INSTALL_TARGET_CMDS
        $(TARGET_MAKE_ENV) $(MAKE) -C $(@D) install DESTDIR=$(TARGET_DIR) CPU_MODEL=$(BR2_PACKAGE_VPU_LIB_CPU_MODEL)
endef
endif

$(eval $(generic-package))
