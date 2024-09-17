################################################################################
#
# Makefile for gst-rockchipmpp Buildroot Package
#
################################################################################

GST_ROCKCHIPMPP_VERSION = 1.0
GST_ROCKCHIPMPP_SITE_METHOD = local
GST_ROCKCHIPMPP_SITE = /home/nikita/src/gstreamer-rockchip
GST_ROCKCHIPMPP_LICENSE = LGPL-2.1+
GST_ROCKCHIPMPP_LICENSE_FILES = COPYING
GST_ROCKCHIPMPP_DEPENDENCIES = host-pkgconf gstreamer1 gst1-plugins-base 

GST_ROCKCHIPMPP_MAKE_OPTS = \
    CC="$(TARGET_CC)" \
    LD="$(TARGET_LD)" \
	PKG_CONFIG="$(PKG_CONFIG_HOST_BINARY)"
	LUCKFOX_PICO_SDK_DIR="/home/nikita/src/luckfox-pico"
	

define GST_ROCKCHIPMPP_BUILD_CMDS
    $(MAKE) $(GST_ROCKCHIPMPP_MAKE_OPTS) -C $(@D)/gst/rockchipmpp
endef

define GST_ROCKCHIPMPP_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/gst/rockchipmpp/libgstrockchipmpp.so $(TARGET_DIR)/usr/lib/gstreamer-1.0/libgstrockchipmpp.so
endef

$(eval $(generic-package))