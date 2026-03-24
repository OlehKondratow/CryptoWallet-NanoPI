#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${1:-cryptowallet-image}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

run_compose() {
  if command -v podman >/dev/null 2>&1 && podman compose version >/dev/null 2>&1; then
    podman compose "$@"
    return
  fi

  if command -v podman-compose >/dev/null 2>&1; then
    podman-compose "$@"
    return
  fi

  if command -v docker >/dev/null 2>&1; then
    docker compose "$@"
    return
  fi

  echo "No compatible compose runtime found (podman compose, podman-compose, docker compose)." >&2
  exit 1
}

if [[ ! -f .env && -f .env.example ]]; then
  cp .env.example .env
fi

# Load local overrides and ensure host cache directories exist.
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

mkdir -p "${YOCTO_DL_DIR:-../downloads}" "${YOCTO_SSTATE_DIR:-../sstate-cache}"

run_compose run --rm yocto-dev bash -lc "\
  ./scripts/bootstrap.sh && \
  source poky/oe-init-build-env build && \
  cp -n conf/bblayers.conf.sample conf/bblayers.conf && \
  cp -n conf/local.conf.sample conf/local.conf && \
  bitbake ${IMAGE_NAME}"
