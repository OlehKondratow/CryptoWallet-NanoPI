#!/usr/bin/env bash
set -euo pipefail

# Paths can be overridden via environment variables.
DEPLOY_DIR="${DEPLOY_DIR:-/data/projects/poky/build/tmp/deploy/images/orange-pi-one}"
NFS_DIR="${NFS_DIR:-/data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/nfsroot}"
TFTP_DIR="${TFTP_DIR:-/data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/tftp}"
KERNEL_IMAGE="${KERNEL_IMAGE:-uImage}"
DTB_FILE="${DTB_FILE:-sun8i-h3-orangepi-one.dtb}"
ROOTFS_TARBALL="${ROOTFS_TARBALL:-core-image-minimal-orange-pi-one.rootfs.tar.bz2}"

require_file() {
  local path="$1"
  [[ -f "$path" ]] || { echo "Missing file: $path" >&2; exit 1; }
}

[[ -d "$DEPLOY_DIR" ]] || { echo "Missing deploy dir: $DEPLOY_DIR" >&2; exit 1; }
mkdir -p "$NFS_DIR" "$TFTP_DIR"

require_file "$DEPLOY_DIR/$KERNEL_IMAGE"
require_file "$DEPLOY_DIR/$DTB_FILE"
require_file "$DEPLOY_DIR/$ROOTFS_TARBALL"

echo "[1/3] Sync TFTP artifacts"
cp -v "$DEPLOY_DIR/$KERNEL_IMAGE" "$TFTP_DIR/$KERNEL_IMAGE"
cp -v "$DEPLOY_DIR/$DTB_FILE" "$TFTP_DIR/$DTB_FILE"

echo "[2/3] Refresh NFS rootfs"
if [[ -d "$NFS_DIR" && "$NFS_DIR" != "/" ]]; then
  sudo rm -rf "${NFS_DIR:?}/"*
fi
sudo tar -xjvf "$DEPLOY_DIR/$ROOTFS_TARBALL" -C "$NFS_DIR"

echo "[3/3] Normalize ownership"
sudo chown -R root:root "$NFS_DIR"

echo "Done:"
echo "  TFTP -> $TFTP_DIR"
echo "  NFS  -> $NFS_DIR"