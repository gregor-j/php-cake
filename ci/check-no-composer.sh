#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <image-tag>" >&2
  exit 2
fi

IMAGE_TAG="$1"

# shellcheck source=ci/runtime-contracts-common.sh
. "$(dirname "$0")/runtime-contracts-common.sh"

run_runtime_contract_check "$IMAGE_TAG" no-composer "No-composer runtime check passed"

