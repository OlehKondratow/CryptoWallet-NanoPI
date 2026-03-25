#!/usr/bin/env bash
# Регистрация Gitea act_runner на NanoPi или другом хосте.
#
# Документация: https://docs.gitea.com/usage/actions/act-runner
#
# В Gitea: Settings -> Actions -> Runners -> Create new runner — URL и registration token.
#
# Пример:
#   export GITEA_INSTANCE_URL="http://192.168.126.3:3000"
#   export GITEA_RUNNER_REGISTRATION_TOKEN="..."
#   # NanoPi NEO (armhf / ARMv7): по умолчанию linux-jake arm-7
#   ./register-act-runner-nanopi.sh
#
# Раннер на ПК (amd64):
#   ARCH_LABEL=linux-amd64 ./register-act-runner-nanopi.sh
#
set -euo pipefail

: "${GITEA_INSTANCE_URL:?Set GITEA_INSTANCE_URL}"
: "${GITEA_RUNNER_REGISTRATION_TOKEN:?Set GITEA_RUNNER_REGISTRATION_TOKEN}"

ACT_RUNNER_VERSION="${ACT_RUNNER_VERSION:-0.2.11}"
# Имя билда из релиза: linux-amd64 | linux-arm-7 | linux-arm64 | ...
ARCH_LABEL="${ARCH_LABEL:-linux-arm-7}"

WORKDIR="${WORKDIR:-$HOME/act-runner}"
mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

XZ_NAME="act_runner-${ACT_RUNNER_VERSION}-${ARCH_LABEL}.xz"
BIN_NAME="act_runner-${ACT_RUNNER_VERSION}-${ARCH_LABEL}"
URL="https://gitea.com/gitea/act_runner/releases/download/v${ACT_RUNNER_VERSION}/${XZ_NAME}"

if [[ ! -f act_runner ]]; then
  curl -fsSL -o "${XZ_NAME}" "${URL}"
  xz -d -k -f "${XZ_NAME}"
  mv -f "${BIN_NAME}" act_runner
  chmod +x act_runner
fi

./act_runner register \
  --instance "${GITEA_INSTANCE_URL}" \
  --token "${GITEA_RUNNER_REGISTRATION_TOKEN}" \
  --no-interactive \
  --labels "${RUNNER_LABELS:-nanopi,self-hosted}"

echo
echo "Запуск (foreground). Для постоянной работы оформи systemd unit:"
echo "  cd ${WORKDIR} && ./act_runner daemon"
