include $(TOPDIR)/rules.mk

PKG_NAME:=obudpst
PKG_VERSION:=9.0.0
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/Dude4Linux/obudpst.git
PKG_SOURCE_VERSION:=109bfcafe46de94a388d573b32671f3ca0935b4f
PKG_MIRROR_HASH:=skip

PKG_MAINTAINER:=Broadband Forum
PKG_LICENSE:=BSD-3-Clause

PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/obudpst
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Open Broadband-UDP Speed Test (OB-UDPST)
  URL:=https://github.com/BroadbandForum/obudpst
endef

define Package/obudpst/description
  OB-UDPST measures maximum IP-layer capacity between a client and one or
  more servers per BBF TR-471 and IETF RFC 9097/9946, using a UDP load test
  with rate feedback in the opposite direction.
endef

# Real binary lives in a private directory; /usr/bin/udpst is a symlink
# maintained by postinst/prerm so a future alternate build (e.g. a Rust
# implementation) can claim the same link without file conflicts.
define Package/obudpst/install
	$(INSTALL_DIR) $(1)/usr/lib/obudpst
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/lib/obudpst/udpst $(1)/usr/lib/obudpst/udpst
endef

define Package/obudpst/postinst
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] && exit 0
ln -sf /usr/lib/obudpst/udpst /usr/bin/udpst
exit 0
endef

define Package/obudpst/prerm
#!/bin/sh
[ -n "$$IPKG_INSTROOT" ] && exit 0
[ "$$(readlink /usr/bin/udpst)" = "/usr/lib/obudpst/udpst" ] && rm -f /usr/bin/udpst
exit 0
endef

$(eval $(call BuildPackage,obudpst))
