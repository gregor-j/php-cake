#!/usr/bin/env sh
set -eu

# Check that all entrypoint hooks are executable and pass ShellCheck.

REPO_ROOT="${1:-.}"
HOOKS_ROOT="${REPO_ROOT}/docker-entrypoint.d"

error_count=0

# Determine which ShellCheck method to use
run_shellcheck() {
  hook_file="$1"

  # Try to use the gregors-bash-library wrapper if available
  if [ -x /home/johamg/Projekte/DevOps/gregors-bash-library/bin/shellcheck.sh ]; then
    /home/johamg/Projekte/DevOps/gregors-bash-library/bin/shellcheck.sh "$hook_file"
    return $?
  fi

  # Fall back to direct shellcheck command
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -S warning "$hook_file"
    return $?
  fi

  printf "Error: Neither shellcheck.sh wrapper nor shellcheck command found\n" >&2
  return 1
}

# Check that hooks directory structure exists
if [ ! -d "${HOOKS_ROOT}" ]; then
  printf "Error: Hooks directory %s does not exist\n" "${HOOKS_ROOT}" >&2
  exit 1
fi

if [ ! -d "${HOOKS_ROOT}/root.d" ] && [ ! -d "${HOOKS_ROOT}/app.d" ]; then
  printf "Error: No hook subdirectories found in %s (expected root.d and/or app.d)\n" "${HOOKS_ROOT}" >&2
  exit 1
fi

# Check executability of all hook files
for hook_dir in "${HOOKS_ROOT}"/*/; do
  [ -d "${hook_dir}" ] || continue

  for hook in "${hook_dir}"/*.sh; do
    [ -e "${hook}" ] || continue

    if [ ! -f "${hook}" ]; then
      printf "Warning: %s is not a regular file\n" "${hook}" >&2
      error_count=$((error_count + 1))
      continue
    fi

    if [ ! -x "${hook}" ]; then
      printf "Error: Hook %s is not executable\n" "${hook}" >&2
      error_count=$((error_count + 1))
    fi
  done
done

# Check ShellCheck compliance for all hook files
for hook_dir in "${HOOKS_ROOT}"/*/; do
  [ -d "${hook_dir}" ] || continue

  for hook in "${hook_dir}"/*.sh; do
    [ -e "${hook}" ] || continue
    [ -f "${hook}" ] || continue

    printf "Checking ShellCheck: %s\n" "${hook}"
    if ! run_shellcheck "${hook}"; then
      error_count=$((error_count + 1))
    fi
  done
done

if [ "${error_count}" -gt 0 ]; then
  printf "\nError: %d entrypoint hook check(s) failed\n" "${error_count}" >&2
  exit 1
fi

printf "All entrypoint hooks are executable and pass ShellCheck\n"
exit 0



