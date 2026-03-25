SUMMARY = "CryptoWallet user-space service (SysV init)"
DESCRIPTION = "Placeholder daemon + init script; replace files/ with real app sources."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://cryptowalletd \
           file://cryptowallet.init \
           file://cryptowallet-cli \
          "

S = "${WORKDIR}"

inherit update-rc.d

INITSCRIPT_NAME = "cryptowallet"
INITSCRIPT_PARAMS = "defaults 99"

RDEPENDS:${PN} += "update-rc.d"

do_install() {
	install -d ${D}${sbindir}
	install -m 0755 ${WORKDIR}/cryptowalletd ${D}${sbindir}/cryptowalletd

	install -d ${D}${bindir}
	install -m 0755 ${WORKDIR}/cryptowallet-cli ${D}${bindir}/cryptowallet

	install -d ${D}${sysconfdir}/init.d
	install -m 0755 ${WORKDIR}/cryptowallet.init ${D}${sysconfdir}/init.d/cryptowallet
}

FILES:${PN} += " \
    ${sbindir}/cryptowalletd \
    ${bindir}/cryptowallet \
    ${sysconfdir}/init.d/cryptowallet \
"
