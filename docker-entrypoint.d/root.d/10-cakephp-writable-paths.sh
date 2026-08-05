#!/usr/bin/env sh
set -eu

APP_ROOT="${APP_ROOT:-/app}"

# Ensure CakePHP writable paths exist on bind mounts before PHP-FPM starts.
mkdir -p \
  "${APP_ROOT}/logs" \
  "${APP_ROOT}/tmp/cache/models" \
  "${APP_ROOT}/tmp/cache/persistent" \
  "${APP_ROOT}/tmp/sessions" \
  "${APP_ROOT}/tmp/tests"

if [ "$(id -u)" -eq 0 ]; then
  chown -R app:app "${APP_ROOT}/logs" "${APP_ROOT}/tmp"
fi

chmod -R u+rwX,g+rwX "${APP_ROOT}/logs" "${APP_ROOT}/tmp"

