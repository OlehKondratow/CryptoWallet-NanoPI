SUMMARY = "CryptoWallet base image for NanoPI NEO"
DESCRIPTION = "Minimal image containing networking, SSH, and CryptoWallet app placeholder."
LICENSE = "MIT"

inherit core-image

IMAGE_FEATURES += "ssh-server-dropbear"

IMAGE_INSTALL:append = " \
    packagegroup-core-boot \
    ca-certificates \
    openssh-sftp-server \
    cryptowallet \
"
