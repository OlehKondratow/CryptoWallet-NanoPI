# Image policy

Use these directories to separate SD card roles and avoid accidental overwrites.

- `dev/` -> active development images (16 GB SD)
- `staging/` -> integration test images
- `release/` -> approved project images (32 GB SD)
- `recovery/` -> minimal rescue images (4 GB SD); см. `recovery/README.md` и `recovery/stage-from-deploy.sh`

Suggested filename format:

`cryptowallet-<slot>-<yyyy-mm-dd>-<shortsha>.img.zst`
