# NanoPi Workspace

This directory stores board-specific artifacts and netboot infrastructure files.

## Image Slots

- `images/dev` - everyday development images
- `images/staging` - pre-release validation images
- `images/release` - release candidates and final images
- `images/recovery` - known-good emergency images

## Netboot Layout

- `netboot/tftp` - files served by TFTP (`zImage`, `*.dtb`, optional initramfs)
- `netboot/nfsroot` - exported NFS root filesystem
- `netboot/config` - `dnsmasq` and NFS exports templates
- `netboot/scripts` - helper scripts for setup and checks

---

## CryptoWallet NanoPi (Orange Pi One) Build System

This repository contains a Yocto Project (`scarthgap`) configuration for building a secure OS for a crypto wallet.
The system boots over the network (TFTP + NFS), which allows fast code updates without reflashing the SD card.

## Current Build Configuration (`local.conf`)

- Machine: `orange-pi-one` (Allwinner H3)
- Distro: `poky` (`v5.0.16`)
- Init system: SysVinit (minimal profile)

### Added packages

- `bash` - main shell (instead of BusyBox shell)
- `openssh` - remote access
- `ntp` and `ntpdate` - accurate time synchronization
- `tzdata-europe` - timezone data (Europe/Warsaw)
- `debug-tweaks` feature - root login without password (development only)

## Artifact Mapping (`deploy/images`)

After `bitbake core-image-minimal`, use:

- `uImage` -> deploy to `/tftp/uImage`
- `sun8i-h3-orangepi-one.dtb` -> deploy to `/tftp/sun8i-h3-orangepi-one.dtb`
- `*.rootfs.tar.bz2` -> extract into `/nfsroot/`
- `u-boot-sunxi-with-spl.bin` -> write to SD card (`dd`)

## Deployment Cheatsheet

### 1) Prepare NFS and TFTP

```bash
# Extract rootfs (use sudo to preserve root ownership and permissions)
sudo rm -rf /path/to/nfsroot/*
sudo tar -xjvf core-image-minimal-orange-pi-one.rootfs.tar.bz2 -C /path/to/nfsroot/

# Copy kernel + DTB
cp uImage sun8i-h3-orangepi-one.dtb /path/to/tftp/
```

### 2) Write bootloader to SD

```bash
# WARNING: verify block device name first (sdX)
sudo dd if=u-boot-sunxi-with-spl.bin of=/dev/sdX bs=1024 seek=8
sync
```

## Security Roadmap

The current build is development-open. Planned hardening steps:

- Remove `debug-tweaks` and set a root password
- Enable IMA/EVM signing for ELF binaries
- Store signing keys in HashiCorp Vault (auto-unseal via USB token)
- Add secure boot chain with key hash fused into Allwinner H3 eFUSE

## Boot Procedure

1. Connect UART adapter (115200 baud)
2. Power on the board
3. Ensure U-Boot netboot command sequence is configured:

```bash
tftp ${kernel_addr_r} uImage && tftp ${fdt_addr_r} dtb && bootm
```

## Next Steps

After first successful boot and network checks, you can:

- Add the first Python/C++ service with autostart
- Deploy HashiCorp Vault on the host for initial API testing