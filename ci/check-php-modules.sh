#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <image-tag> <expected-modules-file> [<expected-modules-file> ...]" >&2
  exit 2
fi

IMAGE_TAG="$1"
shift

for expected_file in "$@"; do
  if [ ! -f "$expected_file" ]; then
    echo "Expected modules file not found: $expected_file" >&2
    exit 2
  fi
done

loaded_file="$(mktemp)"
missing_file="$(mktemp)"
trap 'rm -f "$loaded_file" "$missing_file"' EXIT

# Keep only module names (exclude section headers like [PHP Modules]).
docker run --rm --entrypoint php "$IMAGE_TAG" -m \
  | awk 'NF && $0 !~ /^\[/ {print tolower($0)}' \
  | sort -u > "$loaded_file"

for expected_file in "$@"; do
  while IFS= read -r module || [ -n "$module" ]; do
    module="${module%%#*}"
    module="$(echo "$module" | xargs)"
    [ -z "$module" ] && continue

    module_lc="$(echo "$module" | tr '[:upper:]' '[:lower:]')"
    if ! grep -Fxq "$module_lc" "$loaded_file"; then
      echo "$module" >> "$missing_file"
    fi
  done < "$expected_file"
done

sort -u -o "$missing_file" "$missing_file"

if [ -s "$missing_file" ]; then
  echo "Missing expected PHP modules in image $IMAGE_TAG:" >&2
  sed 's/^/- /' "$missing_file" >&2
  echo >&2
  echo "Loaded modules were:" >&2
  cat "$loaded_file" >&2
  exit 1
fi

echo "Module check passed for $IMAGE_TAG using: $*"


