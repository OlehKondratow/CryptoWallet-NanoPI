# CryptoWallet Yocto for NanoPI NEO v1.2

This repository contains a starter Yocto Project layout for building a custom Linux image for NanoPI NEO v1.2, focused on a CryptoWallet appliance use case.

## Goals

- Reproducible Yocto build setup
- Separate custom layer for project-specific recipes
- Base image definition for CryptoWallet runtime
- Clear onboarding steps for local development

## Target board

- Board: NanoPI NEO v1.2
- SoC: Allwinner H3
- Typical `MACHINE`: `nanopi-neo`

## Prerequisites

Install common Yocto host dependencies (example for Ubuntu/Debian):

```bash
sudo apt update
sudo apt install -y gawk wget git diffstat unzip texinfo gcc build-essential \
  chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
  iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev \
  pylint xterm zstd lz4 file locales
```

Python development environment (optional):

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
```

## Bootstrap layout

This repo intentionally does not vendor all upstream Yocto layers.
Instead, it stores:

- `scripts/bootstrap.sh` to clone required layers
- `build/conf/*.sample` with project defaults
- `meta-cryptowallet` custom layer with image and app recipe placeholders

## Quick start

```bash
# 1) Clone this repository
git clone <your-repo-url> CryptoWallet-NanoPI
cd CryptoWallet-NanoPI

# 2) Fetch Yocto sources and layers
./scripts/bootstrap.sh

# 3) Initialize build environment
source poky/oe-init-build-env build

# 4) Apply project config templates
cp conf/bblayers.conf.sample conf/bblayers.conf
cp conf/local.conf.sample conf/local.conf

# 5) Build image
bitbake cryptowallet-image
```

Resulting image artifacts are generated under `build/tmp/deploy/images/nanopi-neo/`.

## Containerized development (recommended)

You can run Yocto builds in a reproducible Docker environment from `infra/`.

```bash
cd infra
cp .env.example .env
./build-image.sh
```

For interactive development shell:

```bash
cd infra
./dev-shell.sh
```

## Layers expected by templates

- `poky` (contains `meta`, `meta-poky`, `meta-yocto-bsp`)
- `meta-openembedded` (`meta-oe`, `meta-networking`, `meta-python`)
- `meta-sunxi` (NanoPI/Allwinner support)
- `meta-cryptowallet` (this repository)

## Next steps

1. Add a real CryptoWallet application recipe in `meta-cryptowallet/recipes-crypto/cryptowallet/`.
2. Configure secure boot/update strategy (e.g. RAUC, swupdate, OSTree).
3. Harden the image (`read-only-rootfs`, minimal packages, SSH policy).
4. Add CI pipeline for deterministic Yocto builds.
