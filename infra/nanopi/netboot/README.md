# Netboot (TFTP + NFS) — Orange Pi One

Netboot assets live under this directory in the repo:

| Role | Path in repo |
|------|----------------|
| TFTP root (staging) | `/data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/tftp/` |
| NFS root (staging) | `/data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/nfsroot/` |
| U-Boot script source | `tftp/boot.cmd` → compile to `boot.scr` with `mkimage` |
| Host service samples | `config/` |

`boot.cmd` assumes the LAN matches the TFTP host: e.g. **192.168.126.0/23** (`255.255.254.0`) so addresses like `192.168.127.166` and server `192.168.126.3` are **one subnet**. If you use **`255.255.255.0` on the board** while the network is **/23**, the board treats `serverip` as remote, TFTP hits **ARP Retry count exceeded**, and you must either set **`netmask 255.255.254.0`** in U-Boot or fix routing. Adjust `gatewayip` to your RouterOS default gateway.

**`nfsroot=` on the board must use the exact same server path** as in **`/etc/exports`** (or the mount times out / fails). Many labs export **`.../infra/nanopi/netboot/nfsroot`** directly; others **`rsync`** to **`/srv/cryptowallet-netboot/nfsroot`** and export that — then **`boot.cmd` `setenv nfsroot`** must match. TFTP often still uses **`/srv/.../tftp`** or repo **`tftp/`**; only NFS path pairing is critical here.

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

## Build `boot.scr` and copy to the SD card (FAT)

After editing `boot.cmd`, wrap it with `mkimage` (package **`u-boot-tools`** on Debian/Ubuntu). U-Boot on the Orange Pi One looks for **`/boot.scr`** on the first FAT partition (`mmc0:1`).

Replace **`/dev/mmcblk0p1`** if your reader exposes another device (e.g. USB adapter → often `/dev/sdX1`).

```bash
cd /data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/tftp

sudo mount /dev/mmcblk0p1 /mnt
sudo mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n 'netboot nfs' -d boot.cmd boot.scr
sudo cp boot.scr /mnt/
sync
sudo umount /mnt
```

Also keep **`boot.scr`** (and `uImage` / DTB) in this **`tftp/`** tree and **`rsync`** to `/srv/cryptowallet-netboot/tftp/` if the board loads the kernel from the network copy instead of SD-only script.

## Successful boot (UART reference)

With **`boot.cmd`** using **`255.255.254.0`**, board **`192.168.127.166`**, server **`192.168.126.3`**, and **`boot.scr`** on **`mmc0:1`**, a good serial log (115200 8N1) looks like this chain:

1. **SPL / U-Boot** from MMC (`Trying to boot from MMC1`).
2. `Found U-Boot script /boot.scr` → script runs → `TFTP from server 192.168.126.3; our IP address is 192.168.127.166`.
3. **`uImage`** loads (~5.2 MiB typical) then **`sun8i-h3-orangepi-one.dtb`**.
4. `## Booting kernel from Legacy Image at 42000000` → checksum OK → FDT relocated → **`Starting kernel ...`**
5. **Linux** prints `Machine model: Xunlong Orange Pi One` and a command line including **`root=/dev/nfs`**, **`nfsroot=`** with the **same path your NFS server exports**, and **`ip=...`** (kernel **6.6.x** is typical).
6. Within a few seconds of **`IP-Config: Complete`**, you should see **`VFS: Mounted root (nfs filesystem)`**, then **`Run /sbin/init`**, **INIT**, and finally a **login** prompt (e.g. `orange-pi-one login:`).

Quoted reference: **`docs/uart-boot-success-excerpt.md`**.

If TFTP works but the kernel stalls on NFS, see **NFS root mount failure** below. If the reboot hangs before “Starting kernel”, compare **`bootm`** vs **`bootz`** and that the file on TFTP is **uImage**, not **zImage**.

## NFS root mount failure

Symptoms (serial, after `IP-Config: Complete`):

- **Long silence** (often **60–120 s** with almost no new lines) — the client is trying NFS; UART capture/mimicom may look “frozen” even though the kernel is waiting on the mount.
- then `VFS: Unable to mount root fs via NFS.`
- then `Kernel panic - not syncing: No working init found`

The **panic is misleading**: the kernel never mounted NFS, so there is no `/sbin/init` yet. Fix NFS, not `init`. For logging, use **`timeout 180`** (or longer) when capturing **`cat /dev/ttyUSB0`**.

1. **Kernel `nfsroot` options** — use **`nfsvers=3,tcp,nolock`** in `boot.cmd` (not bare **`v3`**). **`rootwait`** is usually unnecessary after `ip=` has configured the NIC. **Do not** add **`nfsrootdebug`** on **Linux 6.6** — it is **not** a built-in boot parameter (kernel prints *Unknown kernel command line parameters*).
2. **Exported path and content** on the server (path must match `nfsroot=`):

   ```bash
   sudo ls /data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/nfsroot/sbin/init
   sudo exportfs -rav
   showmount -e localhost
   ```

   Use `config/exports.sample`. If **`exports`** points at the **repo** nfsroot, you do not need **`/srv/...`** unless you chose that layout (`setup-netboot-host.sh`).

3. **NFS self-test from the server** (same options as the board; proves **export + tcp/2049 + path**). **`mkdir` first** — otherwise `mount.nfs: mount point ... does not exist`.

   ```bash
   sudo mkdir -p /mnt/nfs-selftest
   sudo mount -t nfs -o nfsvers=3,tcp,nolock 192.168.126.3:/data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/nfsroot /mnt/nfs-selftest
   ls /mnt/nfs-selftest/sbin/init
   sudo umount /mnt/nfs-selftest
   ```

   If this fails, fix exports / `nfs-kernel-server` / firewall before debugging the board again.

4. **Services**: `nfs-kernel-server` (or `nfs-server`) and **`rpcbind`** running; after edits run **`exportfs -rav`**.
5. **Firewall on the NFS host** must allow NFS (typically **TCP 2049**, plus **rpcbind/mountd** — check **`rpcinfo -p localhost`** and open those ports, or test briefly with the firewall off).

### Path mismatch (`/srv/...` vs repo nfsroot)

If **`/etc/exports`** lists **`.../infra/nanopi/netboot/nfsroot`** but **`boot.cmd`** used **`/srv/cryptowallet-netboot/nfsroot`**, the client mounts the wrong export (or nothing) → long hang → *Unable to mount root fs via NFS*. **`setenv nfsroot`** and **`exports`** must be the **same directory**.

## U-Boot test commands (Orange Pi One)

Board loads a **uImage** and boots with **`bootm`**. Replace the server IP if yours differs (lab TFTP/NFS host: **`192.168.126.3`**).

```bash
setenv serverip 192.168.126.3
dhcp
tftp ${kernel_addr_r} uImage
tftp ${fdt_addr_r} sun8i-h3-orangepi-one.dtb
setenv bootargs 'console=ttyS0,115200 root=/dev/nfs nfsroot=192.168.126.3:/data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/nfsroot,nfsvers=3,tcp,nolock ip=dhcp rw'
bootm ${kernel_addr_r} - ${fdt_addr_r}
```

Persist only after a successful boot:

```bash
saveenv
```

### NanoPi NEO

If `MACHINE` is `nanopi-neo`, use **`zImage`** / **`bootz`** and **`sun8i-h3-nanopi-neo.dtb`** instead; point `nfsroot=` at the same host path if the rootfs is shared.
