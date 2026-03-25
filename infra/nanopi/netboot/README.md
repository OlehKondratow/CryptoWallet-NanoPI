# Netboot (TFTP + NFS) — Orange Pi One

Netboot assets live under this directory in the repo:

| Role | Path in repo |
|------|----------------|
| TFTP root (staging) | `/data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/tftp/` |
| NFS root (staging) | `/data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/nfsroot/` |
| U-Boot script source | `tftp/boot.cmd` → compile to `boot.scr` with `mkimage` |
| Host service samples | `config/` |

On the boot server, dnsmasq/NFS typically use **`/srv/cryptowallet-netboot/tftp`** and **`/srv/cryptowallet-netboot/nfsroot`** (must match `nfsroot=` in the kernel command line). Populate those from the repo dirs (`rsync` — см. `scripts/setup-netboot-host.sh`).

## Populate from Yocto deploy

Deploy directory used in scripts: **`/data/projects/poky/build/tmp/deploy/images/orange-pi-one/`**

```bash
sudo /data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/scripts/create_fs.sh
```

Or run `scripts/setup-netboot-host.sh` for folder creation and printed host steps.

## TFTP payload (Orange Pi One)

- `uImage`
- `sun8i-h3-orangepi-one.dtb`
- `boot.scr` (from `boot.cmd` via `uboot-mkimage` / `mkimage`)

## U-Boot test commands (Orange Pi One)

Board loads a **uImage** and boots with **`bootm`**. Replace the server IP if yours differs (лабораторный TFTP/NFS: **`192.168.126.3`**).

```bash
setenv serverip 192.168.126.3
dhcp
tftp ${kernel_addr_r} uImage
tftp ${fdt_addr_r} sun8i-h3-orangepi-one.dtb
setenv bootargs 'console=ttyS0,115200 root=/dev/nfs nfsroot=192.168.126.3:/srv/cryptowallet-netboot/nfsroot,v3,tcp ip=dhcp rw'
bootm ${kernel_addr_r} - ${fdt_addr_r}
```

Persist only after a successful boot:

```bash
saveenv
```

### NanoPi NEO

If `MACHINE` is `nanopi-neo`, use **`zImage`** / **`bootz`** and **`sun8i-h3-nanopi-neo.dtb`** instead; point `nfsroot=` at the same host path if the rootfs is shared.
