# Docker image for CakePHP

Chainguard/Wolfi based PHP image for CakePHP.

PHP Versions available: `8.1`, `8.3`

Variants available:
- `fpm`/`cli` Production-ready runtime images with no build tools and no Xdebug.
- `dev` Development image with Xdebug, Composer, and build tools.

**List of images**

| PHP Version | Variant | Image                               |
|-------------|---------|-------------------------------------|
| 8.1         | fpm     | `ghcr.io/gregor-j/php-cake:8.1-fpm` |
| 8.1         | cli     | `ghcr.io/gregor-j/php-cake:8.1-cli` |
| 8.1         | dev     | `ghcr.io/gregor-j/php-cake:8.1-dev` |
| 8.3         | fpm     | `ghcr.io/gregor-j/php-cake:8.3-fpm` |
| 8.3         | cli     | `ghcr.io/gregor-j/php-cake:8.3-cli` |
| 8.3         | dev     | `ghcr.io/gregor-j/php-cake:8.3-dev` |

## Xdebug in dev variant

- Xdebug is installed only in `VARIANT=dev`.
- Composer is installed only in `VARIANT=dev` and uses the `app` user's home at `/home/app` (including `/home/app/.composer`).
- Project settings are loaded from `xdebug.ini` via `/etc/php/conf.d/99-xdebug-settings.ini`.
- OPcache is disabled by default in `VARIANT=dev` via `/etc/php/conf.d/99-dev-no-opcache.ini`.
- Keep Docker/Compose host mapping for Linux so PhpStorm is reachable: `--add-host=host.docker.internal:host-gateway`

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
- extra writeable bind mounts required for `/app/tmp` and `/app/logs` in development environment and `tmpfs` mounts for `/app/tmp` in production environment.

## Entrypoint hooks

- `entrypoint.sh` is the generic runtime orchestrator for user remapping, hook execution, and final process handoff.
- Root-level hooks are executed from `/docker-entrypoint.d/root.d/*.sh`.
- App-level hooks are executed from `/docker-entrypoint.d/app.d/*.sh` as user `app`.
- Hooks run in lexicographic order and must be executable.
- The CakePHP writable-path preparation currently lives in `docker-entrypoint.d/root.d/10-cakephp-writable-paths.sh`.

### Adding new hooks

1. Create a new script in the appropriate directory (`root.d/` for root-level initialization, `app.d/` for app-user-level initialization).
2. Use a numeric prefix to control execution order: `10-name.sh`, `20-name.sh`, etc.
3. Make the script executable: `chmod +x docker-entrypoint.d/{root,app}.d/XX-name.sh`.
4. Ensure the script is POSIX/dash-compatible and passes ShellCheck: Run `ci/check-entrypoint-hooks.sh`.
5. Commit the hook script to version control.

## CI module contracts

- Expected modules are tracked in:
  - `ci/expected-php-modules.runtime.txt`
  - `ci/expected-php-modules.dev-extra.txt`
- Validation script: `ci/check-php-modules.sh <image-tag> <expected-modules-file> [<expected-modules-file> ...]`
- Dev Composer contract: `ci/check-dev-composer.sh <image-tag>`
- Runtime no-Composer contract: `ci/check-no-composer.sh <image-tag>`
- Entrypoint hooks check: `ci/check-entrypoint-hooks.sh [repo-root]` (validates executability and ShellCheck compliance)

## CI matrix maintenance

- CI matrix values are maintained in one place (single source of truth):
  `/.github/workflows/ci.yml` in job `define-matrix`.
- Update supported PHP versions and variants only there!

