#!/usr/bin/env bash
set -euo pipefail

# This script prepares local folders and prints host commands.
# It does not modify system services automatically.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TFTP_DIR="${BASE_DIR}/tftp"
NFSROOT_DIR="${BASE_DIR}/nfsroot"
CFG_DIR="${BASE_DIR}/config"

mkdir -p "${TFTP_DIR}" "${NFSROOT_DIR}"

cat <<EOF
Netboot folders prepared:
  TFTP:    ${TFTP_DIR}
  NFSROOT: ${NFSROOT_DIR}

Next steps on host (Ubuntu/Debian):

1) Install services:
   sudo apt update
   sudo apt install -y dnsmasq nfs-kernel-server

2) Copy config templates:
   sudo cp "${CFG_DIR}/dnsmasq.conf.sample" /etc/dnsmasq.d/cryptowallet-netboot.conf
   sudo cp "${CFG_DIR}/exports.sample" /etc/exports.d/cryptowallet-netboot.exports

3) Map paths in configs to real host directories if needed.
   Default expected paths:
     /srv/cryptowallet-netboot/tftp
     /srv/cryptowallet-netboot/nfsroot

4) Create service paths and sync project folders:
   sudo mkdir -p /srv/cryptowallet-netboot
   sudo rsync -a --delete "${TFTP_DIR}/" /srv/cryptowallet-netboot/tftp/
   sudo rsync -a --delete "${NFSROOT_DIR}/" /srv/cryptowallet-netboot/nfsroot/

5) Restart services:
   sudo exportfs -rav
   sudo systemctl restart nfs-kernel-server
   sudo systemctl restart dnsmasq
EOF
