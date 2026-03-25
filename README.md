# CryptoWallet-NanoPI

Yocto **Scarthgap**–based firmware for **Allwinner H3** boards, aimed at a **crypto-wallet–style** appliance: small rootfs, SSH, optional netboot for fast iteration, and a dedicated **`meta-cryptowallet`** layer for the application.

### Lab walkthrough

End-to-end narrative with **commands and sample output** (**Gitea → runners → Poky → TFTP/NFS → netboot debug → app**): **[`docs/lab-journey.md`](docs/lab-journey.md)**.

## What’s in this repository

| Area | Purpose |
|------|---------|
| **`meta-cryptowallet/`** | Custom layer: **`cryptowallet`** package (placeholder daemon + SysV init), **`core-image-minimal.bbappend`** (pulls app into minimal image), **`cryptowallet-image.bb`**. |
| **`build/conf/*.sample`** | Starting **`bblayers.conf`** / **`local.conf`** when the build directory lives next to this repo. |
| **`scripts/bootstrap.sh`** | Clones **poky**, **meta-openembedded**, **meta-sunxi** (branch `scarthgap` by default). |
| **`infra/`** | Container dev shell, board-focused docs, **TFTP + NFS netboot** tree under **`infra/nanopi/netboot/`** (boot scripts, exports samples, **`create_fs.sh`**). |
| **`.gitea/workflows/`** | Example CI: app deploy over SSH, Yocto → netboot publish (optional). |

Upstream trees (**`poky/`**, **`meta-openembedded/`**, **`meta-sunxi/`**) are **not** vendored; run **`./scripts/bootstrap.sh`** after clone.

## Target hardware

| Board (lab) | `MACHINE` | Kernel / DTB (typical netboot) |
|-------------|-----------|----------------------------------|
| **Orange Pi One** | `orange-pi-one` | **uImage** + **`sun8i-h3-orangepi-one.dtb`** (`bootm`) |
| NanoPi NEO v1.2 | `nanopi-neo` | **zImage** + **`sun8i-h3-nanopi-neo.dtb`** (`bootz`) |

SoC: **Allwinner H3**. Default **`build/conf/local.conf.sample`** uses **`orange-pi-one`**.

## Building

### Host packages (Debian/Ubuntu example)

```bash
sudo apt update
sudo apt install -y gawk wget git diffstat unzip texinfo gcc build-essential \
  chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
  iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev \
  pylint xterm zstd lz4 file locales
```

### Bootstrap and first build

```bash
git clone <your-repo-url> CryptoWallet-NanoPI
cd CryptoWallet-NanoPI
./scripts/bootstrap.sh

source poky/oe-init-build-env build
cp conf/bblayers.conf.sample conf/bblayers.conf
cp conf/local.conf.sample conf/local.conf

# Image used for NFS root in the lab (includes cryptowallet via bbappend)
bitbake core-image-minimal

# Or full reference image from the same layer
# bitbake cryptowallet-image
```

Artifacts: **`build/tmp/deploy/images/<machine>/`** (e.g. **`orange-pi-one/`**) — **`uImage`**, **`*.dtb`**, **`*.rootfs.tar.bz2`**, **`u-boot-sunxi-with-spl.bin`**.

Many setups keep **`CryptoWallet-NanoPI`** only for the product repo and use a **separate** Poky workspace (e.g. **`/data/projects/poky/build`**); the same relative paths apply under that build dir once **`meta-cryptowallet`** is in **`bblayers.conf`**.

### Application package

- Recipe: **`meta-cryptowallet/recipes-crypto/cryptowallet/cryptowallet_0.2.bb`**
- Installs **`cryptowalletd`**, **`/etc/init.d/cryptowallet`**, CLI stub **`cryptowallet`**.
- **`core-image-minimal.bbappend`** adds **`IMAGE_INSTALL:append = " cryptowallet "`**.

Replace the **`files/`** scripts with a real binary or add **`SRC_URI`** + **`do_compile`** when you integrate the actual app.

### Container build (optional)

```bash
cd infra
cp .env.example .env
./build-image.sh    # one-shot
./dev-shell.sh      # interactive shell, then same bitbake flow inside
```

## Netboot (lab)

For **TFTP kernel + NFS root** without reflashing SD every time:

- **Docs:** **`infra/nanopi/README.md`**, **`infra/nanopi/netboot/README.md`**, **`infra/nanopi/netboot/docs/uart-boot-success-excerpt.md`**
- **U-Boot script:** **`infra/nanopi/netboot/tftp/boot.cmd`** → **`boot.scr`** (`mkimage`); **`nfsroot=`** must match **`/etc/exports`** exactly (often the repo path **`.../infra/nanopi/netboot/nfsroot`**).
- **Sync deploy → staging:** **`infra/nanopi/netboot/scripts/create_fs.sh`** (defaults match **orange-pi-one** deploy paths in this workspace).

Network gotchas that have bitten this project: **LAN /23** → use **`255.255.254.0`** in U-Boot/kernel **`ip=`**, not **`/24`** alone; **mismatch** between exported NFS path and **`boot.cmd` `nfsroot`** causes long NFS timeouts.

## Layers (`bblayers` template)

- **poky** (`meta`, `meta-poky`, `meta-yocto-bsp`)
- **meta-openembedded** (`meta-oe`, `meta-networking`, `meta-python`, …)
- **meta-sunxi** (Allwinner boards)
- **meta-cryptowallet** (this product layer)

## CI / Gitea

Workflows under **`.gitea/workflows/`** (host runner, board SSH secrets, optional publish to netboot dirs). See comments in **`nanopi-app-ci.yml`** and **`yocto-netboot-publish.yml`**. Runner registration helper: **`infra/gitea/register-act-runner-nanopi.sh`**.

## Python venv (optional)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
```

## Roadmap (high level)

- Replace placeholder **`cryptowallet`** with the real service and packaging.
- Harden images: drop **`debug-tweaks`**, set root password / SSH policy, consider **read-only rootfs** or robust updates (**RAUC** / **swupdate**).
- Narrow attack surface and document a production **distro** (Poky is reference-only for shipping).

## License

Per-recipe **`LICENSE`** / **`LIC_FILES_CHKSUM`** in **`meta-cryptowallet`** (e.g. MIT for the placeholder recipes).
