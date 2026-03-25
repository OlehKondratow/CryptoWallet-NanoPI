SUMMARY = "CryptoWallet base image (Orange Pi One / H3 lab target)"
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
