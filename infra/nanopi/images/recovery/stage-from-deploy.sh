#!/usr/bin/env bash
# Copies a built .wic/.img into infra/nanopi/images/recovery/ with a timestamp.
# Usage: ./stage-from-deploy.sh <path-to.wic|.img|.img.zst>
set -euo pipefail

SRC="${1:?Usage: $0 <image.wic|image.img|image.img.zst>}"
DEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M)"
BASE="cryptowallet-recovery-${STAMP}"

if [[ ! -f "$SRC" ]]; then
  echo "File not found: $SRC" >&2
  exit 1
fi

EXT="${SRC##*.}"
case "$EXT" in
  zst|gz|xz)
    cp -av "$SRC" "${DEST_DIR}/${BASE}.${EXT}"
    OUT="${DEST_DIR}/${BASE}.${EXT}"
    ;;
  wic|img)
    cp -av "$SRC" "${DEST_DIR}/${BASE}.${EXT}"
    OUT="${DEST_DIR}/${BASE}.${EXT}"
    ;;
  *)
    cp -av "$SRC" "${DEST_DIR}/${BASE}-$(basename "$SRC")"
    OUT="${DEST_DIR}/${BASE}-$(basename "$SRC")"
    ;;
esac

( cd "$DEST_DIR" && sha256sum "$(basename "$OUT")" > "${OUT}.sha256" )
echo "OK: $OUT"
echo "     ${OUT}.sha256"
ls -lh "$OUT" "${OUT}.sha256"
