#!/usr/bin/env sh
set -eu

APP_ROOT="${APP_ROOT:-/app}"
ENTRYPOINT_HOOKS_ROOT_DIR="${ENTRYPOINT_HOOKS_ROOT_DIR:-/docker-entrypoint.d/root.d}"
ENTRYPOINT_HOOKS_APP_DIR="${ENTRYPOINT_HOOKS_APP_DIR:-/docker-entrypoint.d/app.d}"

run_hook_dir() {
  hook_dir="$1"

  [ -d "${hook_dir}" ] || return 0

  for hook in "${hook_dir}"/*.sh; do
    [ -e "${hook}" ] || continue
    [ -f "${hook}" ] || continue

    if [ ! -x "${hook}" ]; then
      printf 'Skipping non-executable entrypoint hook: %s\n' "${hook}" >&2
      continue
    fi

    printf 'Running entrypoint hook: %s\n' "${hook}" >&2
    "${hook}"
  done
}

run_app_hook_dir() {
  hook_dir="$1"

  [ -d "${hook_dir}" ] || return 0

  if [ "$(id -u)" -eq 0 ]; then
    su-exec app /usr/local/bin/entrypoint.sh --run-hook-dir "${hook_dir}"
    return 0
  fi

  run_hook_dir "${hook_dir}"
}

run_entrypoint_hooks() {
  run_hook_dir "${ENTRYPOINT_HOOKS_ROOT_DIR}"
  run_app_hook_dir "${ENTRYPOINT_HOOKS_APP_DIR}"
}

can_write_etc() {
  test_file="/etc/.entrypoint-write-test.$$"

  if (umask 077 && : > "${test_file}") 2>/dev/null; then
    rm -f "${test_file}"
    return 0
  fi

  return 1
}

if [ "${1:-}" = "--run-hook-dir" ]; then
  shift
  run_hook_dir "$1"
  exit 0
fi

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

run_entrypoint_hooks

if [ "$(id -u)" -eq 0 ]; then
  if [ "${1:-}" = "php-fpm" ]; then
    # Keep master process as root so FPM can open /proc/self/fd/2 safely.
    # Worker user is configured via pool config (zz-nonroot.conf).
    exec "$@"
  fi

  exec su-exec app "$@"
fi

exec "$@"
