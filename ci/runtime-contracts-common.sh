#!/usr/bin/env bash
set -euo pipefail

run_runtime_contract_check() {
  if [ "$#" -ne 3 ]; then
    echo "Usage: run_runtime_contract_check <image-tag> <mode> <success-message>" >&2
    return 2
  fi

  local image_tag="$1"
  local mode="$2"
  local success_message="$3"

  docker run --rm -i "$image_tag" sh -s -- "$mode" <<'EOF'
set -eu

fail() {
  echo "$1" >&2
  exit 1
}

assert_runtime_user_home() {
  actual_uid="$(id -u)"
  [ "$actual_uid" -ne 0 ] || fail "Expected runtime check to run as non-root user"

  expected_home="/home/app"
  actual_home="${HOME:-}"
  [ "$actual_home" = "$expected_home" ] || fail "Expected HOME=$expected_home, got: ${actual_home:-<unset>}"

  passwd_home="$(grep '^app:' /etc/passwd | cut -d: -f6)"
  [ "$passwd_home" = "$expected_home" ] || fail "Expected passwd home for app to be $expected_home, got: ${passwd_home:-<missing>}"
}

assert_runtime_user_home

mode="$1"
case "$mode" in
  dev-composer)
    composer_bin="$(command -v composer || true)"
    [ "$composer_bin" = "/usr/bin/composer" ] || fail "Expected composer at /usr/bin/composer, got: ${composer_bin:-<missing>}"

    owner_info="$(apk info -W "$composer_bin" 2>/dev/null || true)"
    case "$owner_info" in
      *" is owned by composer-"*) ;;
      *) fail "Expected composer to come from the composer package, got: ${owner_info:-<unknown>}" ;;
    esac

    [ -z "${COMPOSER_HOME:-}" ] || fail "Expected COMPOSER_HOME to be unset/empty, got: $COMPOSER_HOME"
    [ -z "${COMPOSER_CACHE_DIR:-}" ] || fail "Expected COMPOSER_CACHE_DIR to be unset/empty, got: $COMPOSER_CACHE_DIR"

    [ -d "$expected_home" ] || fail "Expected home directory to exist: $expected_home"
    home_mode="$(stat -c "%a" "$expected_home")"
    [ "$home_mode" = "700" ] || fail "Expected $expected_home permissions to be 700, got: $home_mode"

    expected_cache_dir="${expected_home}/.composer/cache"
    actual_cache_dir="$(composer config --global cache-dir)"
    [ "$actual_cache_dir" = "$expected_cache_dir" ] || fail "Expected composer cache dir $expected_cache_dir, got: $actual_cache_dir"

    composer_config_file="${expected_home}/.composer/config.json"
    composer config --global cache-files-ttl 0 >/dev/null
    [ -f "$composer_config_file" ] || fail "Expected composer config file to be created: $composer_config_file"
    grep -Fq "\"cache-files-ttl\": 0" "$composer_config_file" || fail "Expected composer config file to contain cache-files-ttl setting"
    ;;
  no-composer)
    if command -v composer >/dev/null 2>&1; then
      fail "Composer must not be present in this runtime image"
    fi
    ;;
  *)
    fail "Unknown runtime contract mode: $mode"
    ;;
esac
EOF

  echo "$success_message for $image_tag"
}

