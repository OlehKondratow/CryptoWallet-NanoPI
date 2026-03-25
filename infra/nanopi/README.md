# NanoPi Workspace

This directory stores board-specific artifacts and netboot infrastructure files.

## Image Slots

- `images/dev` - everyday development images
- `images/staging` - pre-release validation images
- `images/release` - release candidates and final images
- `images/recovery` - known-good emergency images

## Netboot Layout

- `netboot/tftp/` — staging for TFTP (here: `uImage`, `sun8i-h3-orangepi-one.dtb`, `boot.cmd` → `boot.scr`); full path on this workspace: `/data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/tftp/`
- `netboot/nfsroot/` — NFS root tree before rsync to the host export; same workspace: `.../infra/nanopi/netboot/nfsroot/`
- `netboot/config/` — `dnsmasq` and NFS `exports` samples; **`exports` path must match `boot.cmd`** (lab often uses repo **`netboot/nfsroot/`**, not only `/srv/...`)
- `netboot/scripts/` — `setup-netboot-host.sh`, `create_fs.sh` (copies from Yocto `deploy` into tftp + nfsroot)

**NFS:** the path in **`boot.cmd` (`nfsroot=`) must match `/etc/exports`** (often **`.../infra/nanopi/netboot/nfsroot`** in the repo). **TFTP** may use **`/srv/.../tftp`** or repo **`tftp/`**; see `setup-netboot-host.sh` for **`/srv`** layout.

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
- `ntp` and **`sntp`** — time sync (legacy **`ntpdate`** is not a separate Yocto package in Scarthgap; use **`sntp`** for one-shot query, **`ntp`** for `ntpd`)
- `tzdata-europe` - timezone data (Europe/Warsaw)
- `debug-tweaks` feature - root login without password (development only)

## Artifact Mapping (`deploy/images/orange-pi-one`)

Default Yocto output on this machine (Poky build dir): **`/data/projects/poky/build/tmp/deploy/images/orange-pi-one/`**

After `bitbake core-image-minimal`, use:

- `uImage` → `infra/nanopi/netboot/tftp/uImage` (and/or `/srv/cryptowallet-netboot/tftp/uImage`)
- `sun8i-h3-orangepi-one.dtb` → same under `tftp/`
- `core-image-minimal-orange-pi-one.rootfs.tar.bz2` → extract into `infra/nanopi/netboot/nfsroot/` (then rsync to `/srv/.../nfsroot/` if needed)
- `u-boot-sunxi-with-spl.bin` → write to SD card (`dd`)

**One-shot sync** from deploy into repo netboot dirs (run with root if `sudo` inside the script must be non-interactive):

```bash
sudo /data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/scripts/create_fs.sh
```

Environment overrides: `DEPLOY_DIR`, `NFS_DIR`, `TFTP_DIR`, `KERNEL_IMAGE`, `DTB_FILE`, `ROOTFS_TARBALL` (see script).

## Deployment Cheatsheet

### 1) Prepare NFS and TFTP

```bash
cd /data/projects/poky/build/tmp/deploy/images/orange-pi-one
# Extract rootfs into repo nfsroot (use sudo to preserve ownership)
sudo rm -rf /data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/nfsroot/*
sudo tar -xjvf core-image-minimal-orange-pi-one.rootfs.tar.bz2 -C /data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/nfsroot/

# Kernel + DTB
cp -v uImage sun8i-h3-orangepi-one.dtb /data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/tftp/
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
3. U-Boot: load **`boot.scr`** from the SD FAT partition (auto-scan) or from TFTP. Build **`boot.scr`** with **`mkimage`** from `infra/nanopi/netboot/tftp/boot.cmd` — step-by-step: **`infra/nanopi/netboot/README.md`** (“Build boot.scr and copy to the SD card”). Kernel **`uImage`**, DTB **`sun8i-h3-orangepi-one.dtb`**, **`bootm`**. TFTP/NFS server: **`192.168.126.3`**; **`nfsroot=`** must match your **exports** (see **`boot.cmd`**). Successful UART excerpts: **`infra/nanopi/netboot/docs/uart-boot-success-excerpt.md`** and **`infra/nanopi/netboot/README.md`** (“Successful boot”).

## Next Steps

After first successful boot and network checks, you can:

- Add the first Python/C++ service with autostart
- Deploy HashiCorp Vault on the host for initial API testing