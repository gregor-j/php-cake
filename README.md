# Docker image for CakePHP

Chainguard/Wolfi based PHP image for CakePHP.

## Xdebug in dev variant

- Xdebug is installed only in `VARIANT=dev`.
- Composer is installed only in `VARIANT=dev` and uses the `app` user's home at `/home/app` (including `/home/app/.composer`).
- Project settings are loaded from `xdebug.ini` via `/etc/php/conf.d/99-xdebug-settings.ini`.
- OPcache is disabled by default in `VARIANT=dev` via `/etc/php/conf.d/99-dev-no-opcache.ini`.
- Keep Docker/Compose host mapping for Linux so PhpStorm is reachable:
  `--add-host=host.docker.internal:host-gateway`

### Xdebug mode

Xdebug is loaded but **inactive by default** (`xdebug.mode=off`).
This prevents connection errors when no debugger is listening.

Activation is done via the `XDEBUG_MODE` environment variable, which Xdebug 3 reads natively and uses to override the ini value – no separate config file needed.

| Scenario                    | `XDEBUG_MODE` value |
|-----------------------------|---------------------|
| Normal operation (inactive) | *(unset or `off`)*  |
| Debugging (development)     | `debug`             |
| Coverage (CI pipeline)      | `coverage`          |
| Both combined               | `debug,coverage`    |

**Examples:**

```yaml
# docker-compose.yml – persistent activation per service
services:
  php:
    environment:
      XDEBUG_MODE: debug
```

```bash
# One-off invocation – no config change needed
XDEBUG_MODE=coverage docker-compose exec -T php vendor/bin/phpunit --coverage-text
```

## Read-only runtime notes

- `tmpfs` mounts required for `/tmp`, `/run`, `/var/run`, `/var/lib/php/opcache`
- extra non-read-only bind mounts required for `/app/tmp` and `/app/logs` in development environment and `tmpfs` mounts for `/app/tmp` in production environment.

## CI module contracts

- Expected modules are tracked in:
  - `ci/expected-php-modules.runtime.txt`
  - `ci/expected-php-modules.dev-extra.txt`
- Validation script: `ci/check-php-modules.sh <image-tag> <expected-modules-file> [<expected-modules-file> ...]`
- Dev Composer contract: `ci/check-dev-composer.sh <image-tag>`
- Runtime no-Composer contract: `ci/check-no-composer.sh <image-tag>`

## CI matrix maintenance

- CI matrix values are maintained in one place (single source of truth):
  `/.github/workflows/ci.yml` in job `define-matrix`.
- Update supported PHP versions and variants only there.

