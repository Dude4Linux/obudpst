include $(TOPDIR)/rules.mk

PKG_NAME:=obudpst
PKG_VERSION:=9.0.0
PKG_RELEASE:=4

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/Dude4Linux/obudpst.git
PKG_SOURCE_VERSION:=afe796f5605fb52290e2548698689b60df100302
PKG_MIRROR_HASH:=skip

PKG_MAINTAINER:=Broadband Forum
PKG_LICENSE:=BSD-3-Clause

PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

# CMakeLists.txt treats OpenSSL as optional and quietly builds without
# authentication when it is missing (an SDK without libopenssl staged); fail
# the build instead of shipping a server that accepts anyone.
CMAKE_OPTIONS += -DCMAKE_REQUIRE_FIND_PACKAGE_OpenSSL=TRUE

define Package/obudpst
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Open Broadband-UDP Speed Test (OB-UDPST)
  URL:=https://github.com/BroadbandForum/obudpst
  # OpenSSL >= 3.0 turns on AUTH_KEY_ENABLE (HMAC-SHA256 setup/activation
  # authentication, -a key / -K keyfile); without it the server accepts
  # unauthenticated tests from anyone who can reach the control port.
  DEPENDS:=+libopenssl +udpst-common
  # The shared "udpst" alternative behind udpst-common's /usr/bin/udpst
  # wrapper; udpst-rs registers at 60 and is the default when both are
  # installed.
  ALTERNATIVES:=50:/usr/libexec/udpst/udpst:/usr/lib/obudpst/udpst
endef

define Package/obudpst/description
  OB-UDPST measures maximum IP-layer capacity between a client and one or
  more servers per BBF TR-471 and IETF RFC 9097/9946, using a UDP load test
  with rate feedback in the opposite direction.
endef

# The real binary lives in a private directory. The SDK's default
# postinst/prerm maintain the alternative link from ALTERNATIVES (OpenWrt has
# no manual selection: pick an implementation with UDPST_IMPL in
# /etc/default/udpst instead).
define Package/obudpst/install
	$(INSTALL_DIR) $(1)/usr/lib/obudpst
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/lib/obudpst/udpst $(1)/usr/lib/obudpst/udpst
endef

# Restart an enabled server on the new binary, or on removal fall back to
# udpst-rs or stop (fail closed). udpst-common may be removed first.
define Package/obudpst/postinst
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] && exit 0
. /usr/share/udpst/functions.sh && udpst_service_refresh
exit 0
endef

define Package/obudpst/postrm
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] && exit 0
[ -r /usr/share/udpst/functions.sh ] && . /usr/share/udpst/functions.sh && udpst_service_refresh
exit 0
endef

$(eval $(call BuildPackage,obudpst))
