#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

# You can override these branches as needed.
YOCTO_BRANCH="${YOCTO_BRANCH:-scarthgap}"
POKY_REPO="${POKY_REPO:-https://git.yoctoproject.org/poky}"
META_OE_REPO="${META_OE_REPO:-https://git.openembedded.org/meta-openembedded}"
META_SUNXI_REPO="${META_SUNXI_REPO:-https://github.com/linux-sunxi/meta-sunxi.git}"

clone_if_missing() {
  local repo_url="$1"
  local target_dir="$2"
  local branch="$3"

  if [[ -d "${target_dir}/.git" ]]; then
    echo "[skip] ${target_dir} already exists"
    return
  fi

  echo "[clone] ${repo_url} -> ${target_dir} (branch: ${branch})"
  git clone --branch "${branch}" --single-branch "${repo_url}" "${target_dir}"
}

clone_if_missing "${POKY_REPO}" "poky" "${YOCTO_BRANCH}"
clone_if_missing "${META_OE_REPO}" "meta-openembedded" "${YOCTO_BRANCH}"
clone_if_missing "${META_SUNXI_REPO}" "meta-sunxi" "${YOCTO_BRANCH}"

echo
echo "Bootstrap complete."
echo "Next:"
echo "  source poky/oe-init-build-env build"
echo "  cp conf/bblayers.conf.sample conf/bblayers.conf"
echo "  cp conf/local.conf.sample conf/local.conf"
echo "  bitbake cryptowallet-image"
