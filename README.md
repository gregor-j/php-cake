# Docker image for CakePHP

Chainguard/Wolfi based PHP image for CakePHP.

## Xdebug in dev variant

- Xdebug is installed only in `VARIANT=dev`.
- Project settings are loaded from `xdebug.ini` via `/etc/php/conf.d/99-xdebug-settings.ini`.
- Keep Docker/Compose host mapping for Linux so PhpStorm is reachable:
  `--add-host=host.docker.internal:host-gateway`

## CI module contracts

- Expected modules are tracked in:
  - `ci/expected-php-modules.runtime.txt`
  - `ci/expected-php-modules.dev-extra.txt`
- Validation script: `ci/check-php-modules.sh <image-tag> <expected-modules-file> [<expected-modules-file> ...]`

## CI matrix maintenance

- CI matrix values are maintained in one place (single source of truth):
  `/.github/workflows/ci.yml` in job `define-matrix`.
- Update supported PHP versions and variants only there.

