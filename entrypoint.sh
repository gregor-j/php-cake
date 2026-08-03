#!/usr/bin/env sh
set -eu

APP_USER="${APP_USER:-app}"
APP_ROOT="${APP_ROOT:-/app}"

# Optional: mappe den Container-User auf Host-UID/GID fuer bind mounts.
if [ "$(id -u)" -eq 0 ]; then
  TARGET_GID="${HOST_GID:-$(id -g "${APP_USER}")}"
  TARGET_UID="${HOST_UID:-$(id -u "${APP_USER}")}"

  if [ "${TARGET_GID}" != "$(id -g "${APP_USER}")" ]; then
      groupmod -o -g "${TARGET_GID}" "${APP_USER}"
  fi
  if [ "${TARGET_UID}" != "$(id -u "${APP_USER}")" ]; then
      usermod -o -u "${TARGET_UID}" -g "${TARGET_GID}" "${APP_USER}"
  fi
fi

# Ensure CakePHP writable paths exist on bind mounts before PHP-FPM starts.
mkdir -p \
  "${APP_ROOT}/logs" \
  "${APP_ROOT}/tmp/cache/models" \
  "${APP_ROOT}/tmp/cache/persistent" \
  "${APP_ROOT}/tmp/sessions" \
  "${APP_ROOT}/tmp/tests"

# Rechte nur setzen, wenn als root gestartet.
if [ "$(id -u)" -eq 0 ]; then
  chown -R "${APP_USER}:${APP_USER}" "${APP_ROOT}/logs" "${APP_ROOT}/tmp"
fi
chmod -R u+rwX,g+rwX "${APP_ROOT}/logs" "${APP_ROOT}/tmp"

if [ "$(id -u)" -eq 0 ]; then
  exec su-exec "${APP_USER}" "$@"
fi

exec "$@"
