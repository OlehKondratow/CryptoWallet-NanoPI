# Infra Development Kit

This directory contains a containerized development environment for Yocto builds.
It is compatible with `podman compose` and `docker compose`.

## Files

- `Dockerfile` - Dev image with Yocto host dependencies and `kas`
- `docker-compose.yml` - Reproducible runtime configuration
- `.env.example` - Tunables for branch, threads, and cache paths
- `dev-shell.sh` - Open interactive shell in the dev container
- `build-image.sh` - Build a Yocto image in one command

## Quick start

```bash
cd infra
cp .env.example .env
./dev-shell.sh
```

Runtime resolution in scripts:

- `podman compose` (preferred)
- `podman-compose`
- `docker compose` (fallback)

Inside the container:

```bash
./scripts/bootstrap.sh
source poky/oe-init-build-env build
cp conf/bblayers.conf.sample conf/bblayers.conf
cp conf/local.conf.sample conf/local.conf
bitbake cryptowallet-image
```

One-shot build from host:

```bash
cd infra
./build-image.sh
```

Build custom image target:

```bash
./build-image.sh core-image-minimal
```
