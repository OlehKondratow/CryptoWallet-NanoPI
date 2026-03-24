SUMMARY = "CryptoWallet application placeholder"
DESCRIPTION = "Temporary recipe that installs a marker file until real app integration is ready."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${bindir}
    cat << 'EOF' > ${D}${bindir}/cryptowallet
#!/bin/sh
echo "CryptoWallet placeholder binary. Replace via real recipe."
EOF
    chmod 0755 ${D}${bindir}/cryptowallet
}

FILES:${PN} += "${bindir}/cryptowallet"
