#!/usr/bin/env sh
set -eu

APP_ROOT="${APP_ROOT:-/app}"

can_write_etc() {
  test_file="/etc/.entrypoint-write-test.$$"

  if (umask 077 && : > "${test_file}") 2>/dev/null; then
    rm -f "${test_file}"
    return 0
  fi

  return 1
}

# Optional: mapping container user to host UID/GID for bind mounts.
if [ "$(id -u)" -eq 0 ]; then
  CURRENT_GID="$(id -g app)"
  CURRENT_UID="$(id -u app)"

  if can_write_etc && [ -w /etc/group ] && [ -w /etc/passwd ] && { [ ! -e /etc/shadow ] || [ -w /etc/shadow ]; }; then
    TARGET_GID="${HOST_GID:-${CURRENT_GID}}"
    TARGET_UID="${HOST_UID:-${CURRENT_UID}}"

    if [ "${TARGET_GID}" != "${CURRENT_GID}" ]; then
      groupmod -o -g "${TARGET_GID}" app
    fi
    if [ "${TARGET_UID}" != "${CURRENT_UID}" ]; then
      usermod -o -u "${TARGET_UID}" -g "${TARGET_GID}" app
    fi
  elif [ -n "${HOST_GID:-}" ] || [ -n "${HOST_UID:-}" ]; then
    printf "Skipping HOST_UID/HOST_GID remapping because /etc is not writable.\n" >&2
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
