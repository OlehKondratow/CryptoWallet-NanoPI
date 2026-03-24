#!/usr/bin/env bash
set -euo pipefail

mkdir -p /work/downloads /work/sstate-cache /work/build

exec "$@"
