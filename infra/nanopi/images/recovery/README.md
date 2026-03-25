# Recovery slot (4 GB microSD)

**Image binaries are not committed here** — only this description and helper scripts. Files are large; keep them on disk or in CI artifacts.

## What to store

- Minimal **known-good** image for your current build (lab board: **Orange Pi One**, `orange-pi-one`): boot, SSH, network, recovery utilities.
- Filename convention:

  `cryptowallet-recovery-<yyyy-mm-dd>-<git-sha>.img.zst`

- Place a checksum next to it: `.sha256`

## Where to get an image

1. Build with Yocto (`bitbake cryptowallet-image` or `core-image-minimal`) and take `.wic` / `.img` from the deploy dir for `MACHINE`, e.g. **`/data/projects/poky/build/tmp/deploy/images/orange-pi-one/`** (or `build/tmp/deploy/images/orange-pi-one/` inside your Poky tree).
2. Or dump from a working 4 GB card:

   ```bash
   sudo dd if=/dev/mmcblk0 bs=4M status=progress | zstd -19 -T0 -o cryptowallet-recovery-$(date +%F).img.zst
   sha256sum cryptowallet-recovery-*.img.zst > cryptowallet-recovery-*.img.zst.sha256
   ```

## Copy an artifact into this directory

From the repository root (after a build):

```bash
cd /data/projects/CryptoWallet-NanoPI
# use the real .wic/..deploy name (depends on IMAGE_FSTYPES)
./infra/nanopi/images/recovery/stage-from-deploy.sh /data/projects/poky/build/tmp/deploy/images/orange-pi-one/core-image-minimal-orange-pi-one.wic
# or a compressed image path:
./infra/nanopi/images/recovery/stage-from-deploy.sh /data/projects/CryptoWallet-NanoPI/cryptowallet-recovery-2025-03-01.img.zst
```

The script writes a **timestamped copy into this directory** (not tracked by git).

## Usage

- Label the SD **RESCUE-4**.
- In an emergency: insert the card, boot, repair the main system, or reflash the dev card.
