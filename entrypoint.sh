#!/usr/bin/env sh
set -eu

APP_ROOT="${APP_ROOT:-/app}"

# Optional: mappe den Container-User auf Host-UID/GID fuer bind mounts.
if [ "$(id -u)" -eq 0 ]; then
  TARGET_GID="${HOST_GID:-$(id -g app)}"
  TARGET_UID="${HOST_UID:-$(id -u app)}"

  if [ "${TARGET_GID}" != "$(id -g app)" ]; then
      groupmod -o -g "${TARGET_GID}" app
  fi
  if [ "${TARGET_UID}" != "$(id -u app)" ]; then
      usermod -o -u "${TARGET_UID}" -g "${TARGET_GID}" app
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
  chown -R app:app "${APP_ROOT}/logs" "${APP_ROOT}/tmp"
fi
chmod -R u+rwX,g+rwX "${APP_ROOT}/logs" "${APP_ROOT}/tmp"

if [ "$(id -u)" -eq 0 ]; then
  if [ "${1:-}" = "php-fpm" ]; then
    # Keep master process as root so FPM can open /proc/self/fd/2 safely.
    # Worker user is configured via pool config (zz-nonroot.conf).
    exec "$@"
  fi

  exec su-exec app "$@"
fi

exec "$@"
