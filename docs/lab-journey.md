# Lab journey: Gitea → Poky → TFTP/NFS → netboot → first app

A **command-oriented story**: how this lab is wired, with **example commands and representative output**. Adjust **IPs**, **paths**, and **`MACHINE`** for your site.

**Reference lab:** Orange Pi One (`orange-pi-one`), host **ws8**, repo **`/data/projects/CryptoWallet-NanoPI`**, Poky build often **`/data/projects/poky/build`**, LAN **192.168.126.0/23**, services on **192.168.126.3**.

---

## 1. Gitea and runners

**Goal:** keep the product in **self-hosted Git** and run Actions (build, publish to netboot, optional board reboot) without GitHub.

Gitea listens on the **host LAN IP** (e.g. **`http://192.168.126.3:3000`**). Use that URL from the board; do not confuse it with a Docker **macvlan** or other secondary address unless you route to it.

**Register [act_runner](https://docs.gitea.com/usage/actions/act-runner)** on the build PC (amd64) and optionally on an ARM board (`linux-arm-7` artifact).

```bash
cd /data/projects/CryptoWallet-NanoPI
export GITEA_INSTANCE_URL="http://192.168.126.3:3000"
export GITEA_RUNNER_REGISTRATION_TOKEN="<paste-from-gitea>"
# PC runner:
ARCH_LABEL=linux-amd64 ./infra/gitea/register-act-runner-nanopi.sh
```

Example console tail after registration (then run the daemon as documented):

```text
Running in foreground. For production, create a systemd unit:
  cd /home/you/act-runner && ./act_runner daemon
```

Workflows live under **`.gitea/workflows/`**: **`simple-ci.yml`**, **`nanopi-app-ci.yml`** (SSH deploy; secrets **`NANPI_HOST`**, **`NANPI_USER`**, **`NANPI_SSH_KEY`**), **`yocto-netboot-publish.yml`** (copy kernel/dtb/rootfs to netboot dirs on the runner host).

---

## 2. Poky setup and build

**Goal:** Scarthgap image with **`core-image-minimal`** plus **`cryptowallet`** (**`meta-cryptowallet/recipes-core/images/core-image-minimal.bbappend`**).

Clone upstream layers (once):

```bash
cd /data/projects/CryptoWallet-NanoPI
./scripts/bootstrap.sh
```

Typical transcript (layers already present):

```text
[skip] poky already exists
[skip] meta-openembedded already exists
[skip] meta-sunxi already exists

Bootstrap complete.
Next:
  source poky/oe-init-build-env build
  cp conf/bblayers.conf.sample conf/bblayers.conf
  cp conf/local.conf.sample conf/local.conf
  bitbake core-image-minimal
```

Configure **`bblayers.conf`** so **`meta-cryptowallet`** points at this repo. **`local.conf`** excerpt (note: **no `ntpdate`** in Scarthgap — use **`ntp`** + **`sntp`**):

```bash
MACHINE = "orange-pi-one"
IMAGE_FSTYPES = "tar.bz2 ext4"
IMAGE_INSTALL:append = " bash openssh tzdata tzdata-europe ntp sntp"
EXTRA_IMAGE_FEATURES ?= "debug-tweaks"
```

If you still have **`ntpdate`** in **`IMAGE_INSTALL`**, BitBake fails:

```text
ERROR: Nothing RPROVIDES 'ntpdate' (but ... core-image-minimal.bb RDEPENDS on or otherwise requires it)
ERROR: Required build target 'core-image-minimal' has no buildable providers.
```

Fix the line, then:

```bash
cd /data/projects/poky/build
source ../oe-init-build-env .
bitbake core-image-minimal
```

Successful runs end with task completion and images under:

```bash
ls /data/projects/poky/build/tmp/deploy/images/orange-pi-one/
```

```text
core-image-minimal-orange-pi-one.rootfs.tar.bz2
sun8i-h3-orangepi-one.dtb
u-boot-sunxi-with-spl.bin
uImage
...
```

**Host note:** Ubuntu **24.10** may print a *Host distribution … not been validated* warning; builds often still work, or use **`infra/dev-shell.sh`** / an LTS host.

**Hash equivalence / missing Unix socket:** Poky sets **`BB_HASHSERVE ??= "auto"`** so BitBake talks to a local hash server over **`unix://…`**. If that socket is gone (crashed cooker, stale server, or **`bitbake`** reconnect issues), tasks can fail in **`sstate_report_unihash`** with:

```text
FileNotFoundError: [Errno 2] No such file or directory
  ... hashserv.create_client ... sock.connect
```

**Fix (stable):** in **`local.conf`**, **`BB_SIGNATURE_HANDLER = "OEBasicHash"`** so builds do not require that client. **Alternative:** `bitbake --kill-server`, then **`source poky/oe-init-build-env`** and rebuild so a fresh hash server and socket are created.

---

## 3. TFTP and NFS

**Goal:** stage **kernel + DTB + `boot.scr`** for TFTP and an **NFS root** tree; **`exports`** path must equal **`nfsroot=`** in the kernel cmdline (**`boot.cmd`** → **`boot.scr`**).

Prepare dirs and print host hints:

```bash
./infra/nanopi/netboot/scripts/setup-netboot-host.sh
```

Sync Yocto **`deploy`** into repo staging (paths match **`create_fs.sh`** defaults):

```bash
sudo /data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/scripts/create_fs.sh
```

Example fragments:

```text
[1/3] Sync TFTP artifacts
.../uImage -> .../infra/nanopi/netboot/tftp/uImage
.../sun8i-h3-orangepi-one.dtb -> .../tftp/sun8i-h3-orangepi-one.dtb
[2/3] Refresh NFS rootfs
[3/3] Normalize ownership
Done:
  TFTP -> /data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/tftp
  NFS  -> /data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/nfsroot
```

**`/etc/exports.d/cryptowallet-netboot.exports`** (example — must match **`setenv nfsroot`** in **`boot.cmd`**):

```nfs
/data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/nfsroot 192.168.126.0/23(rw,sync,no_subtree_check,no_root_squash)
```

Apply:

```bash
sudo exportfs -rav
showmount -e localhost
```

**Loopback NFS check** (mountpoint must exist):

```bash
sudo mkdir -p /mnt/nfs-selftest
sudo mount -t nfs -o nfsvers=3,tcp,nolock \
  192.168.126.3:/data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/nfsroot /mnt/nfs-selftest
ls /mnt/nfs-selftest/sbin/init
sudo umount /mnt/nfs-selftest
```

```text
/mnt/nfs-selftest/sbin/init
```

If you skip **`mkdir`**, you get:

```text
mount.nfs: mount point /mnt/nfs-selftest does not exist
```

---

## 4. Netboot bring-up and debugging

**SD card:** SPL/U-Boot only (typical Allwinner offset):

```bash
cd /data/projects/poky/build/tmp/deploy/images/orange-pi-one
sudo dd if=u-boot-sunxi-with-spl.bin of=/dev/mmcblk0 bs=1024 seek=8 conv=fsync
sync
```

**`boot.scr`** from **`infra/nanopi/netboot/tftp/boot.cmd`**:

```bash
cd /data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/tftp
sudo mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n 'netboot nfs' -d boot.cmd boot.scr
```

```text
Image Name:   netboot nfs
Image Type:   ARM Linux Script (uncompressed)
Data Size:    ... Bytes
```

Copy **`boot.scr`** to the FAT partition, e.g.:

```bash
sudo mount /dev/mmcblk0p1 /mnt
sudo cp boot.scr /mnt/
sync
sudo umount /mnt
```

**Pitfalls we saw (UART 115200):**

| Symptom | Cause | Fix |
|--------|--------|-----|
| **`ipaddr` not set`** before TFTP | **`tftp`** before DHCP/static in U-Boot | Add **`dhcp`** or set **`ipaddr`/`netmask`/`gatewayip`** before **`tftp`** |
| **`ARP Retry count exceeded`** to **.126.3** | Board **`/24`** while LAN is **`/23`** | **`setenv netmask 255.255.254.0`**, same in kernel **`ip=`** |
| Long hang → **Unable to mount root NFS**; **No working init** | **`nfsroot=` path ≠ exported path** | Align **`boot.cmd`** and **`/etc/exports`** |
| Kernel warns **`Unknown ... nfsrootdebug`** | Not a valid **6.6** boot arg | Remove **`nfsrootdebug`** from **`bootargs`** |

Success kernel lines (abbreviated):

```text
Kernel command line: ... root=/dev/nfs nfsroot=192.168.126.3:/data/projects/CryptoWallet-NanoPI/infra/nanopi/netboot/nfsroot,nfsvers=3,tcp,nolock ip=192.168.127.166::192.168.126.1:255.255.254.0::eth0:off rw
IP-Config: Complete:
VFS: Mounted root (nfs filesystem) on device 0:13.
Run /sbin/init as init process
```

More detail: **`infra/nanopi/netboot/README.md`**, **`infra/nanopi/netboot/docs/uart-boot-success-excerpt.md`**.

---

## 5. First application / service start

**Goal:** **`cryptowallet`** recipe (**`meta-cryptowallet`**) installs **`cryptowalletd`**, **`/etc/init.d/cryptowallet`**, and a small **`cryptowallet`** CLI.

On the board after login:

```bash
cryptowallet
```

```text
cryptowallet 0.2 (placeholder)
Service: /etc/init.d/cryptowallet {start|stop|restart}
Log:     /var/log/cryptowalletd.log (after daemon start)
```

```bash
tail -n 5 /var/log/cryptowalletd.log
```

```text
2026-03-25T12:00:00Z cryptowalletd heartbeat
```

With **`debug-tweaks`**, **`root`** often has an **empty password** at the serial login.

Benign messages on NFS root (static **`ip=`** already applied):

```text
Configuring network interfaces... ip: RTNETLINK answers: File exists
ifup skipped for nfsroot interface eth0
run-parts: /etc/network/if-pre-up.d/nfsroot: exit status 1
```

**Product loop:** edit **`files/`** or add a real **`SRC_URI`** build in **`cryptowallet_0.2.bb`** → **`bitbake core-image-minimal`** → **`create_fs.sh`** (or **`yocto-netboot-publish`**) → reboot → verify **`/var/log/cryptowalletd.log`**.

---

## Further reading

| Topic | Location |
|--------|----------|
| Repo layout (English index) | **`README.md`** |
| Board + netboot layout | **`infra/nanopi/README.md`**, **`infra/nanopi/netboot/README.md`** |
| UART success excerpt | **`infra/nanopi/netboot/docs/uart-boot-success-excerpt.md`** |
| Migration context | **`docs/migration-plan-stm32-to-yocto.md`** |
