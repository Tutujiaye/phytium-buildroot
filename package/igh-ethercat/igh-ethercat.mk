################################################################################
#
# igh-ethercat
#
################################################################################

IGH_ETHERCAT_VERSION = bec5f529701a07d0da2730c94e75a777e07eefe0
IGH_ETHERCAT_SITE = https://gitee.com/phytium_embedded/ether-cat.git
IGH_ETHERCAT_INSTALL_IMAGES = YES
IGH_ETHERCAT_SITE_METHOD = git
IGH_ETHERCAT_AUTORECONF = YES


IGH_ETHERCAT_INSTALL_STAGING = YES

IGH_ETHERCAT_CONF_OPTS = \
	--with-linux-dir=$(LINUX_DIR)

IGH_ETHERCAT_CONF_OPTS += $(if $(BR2_PACKAGE_IGH_ETHERCAT_8139TOO),--enable-8139too,--disable-8139too)
IGH_ETHERCAT_CONF_OPTS += $(if $(BR2_PACKAGE_IGH_ETHERCAT_E100),--enable-e100,--disable-e100)
IGH_ETHERCAT_CONF_OPTS += $(if $(BR2_PACKAGE_IGH_ETHERCAT_E1000),--enable-e1000,--disable-e1000)
IGH_ETHERCAT_CONF_OPTS += $(if $(BR2_PACKAGE_IGH_ETHERCAT_E1000E),--enable-e1000e,--disable-e1000e)
IGH_ETHERCAT_CONF_OPTS += $(if $(BR2_PACKAGE_IGH_ETHERCAT_R8169),--enable-r8169,--disable-r8169)

define IGH_ETHERCAT_CREATE_CHANGELOG
	touch $(@D)/ChangeLog
endef

IGH_ETHERCAT_POST_PATCH_HOOKS += IGH_ETHERCAT_CREATE_CHANGELOG

$(eval $(kernel-module))
$(eval $(autotools-package))
