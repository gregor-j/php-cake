# syntax=docker/dockerfile:1.7

ARG PHP_VERSION
ARG VARIANT

FROM cgr.dev/chainguard/wolfi-base:latest AS base

ARG PHP_VERSION

SHELL ["/bin/sh", "-ec"]

RUN : "${PHP_VERSION:?Missing required build arg: PHP_VERSION}"; \
	apk add --no-cache \
	  ca-certificates \
	  shadow \
	  su-exec \
	  tzdata \
	  "php-${PHP_VERSION}" \
	  "php-${PHP_VERSION}-ctype" \
	  "php-${PHP_VERSION}-curl" \
	  "php-${PHP_VERSION}-dom" \
	  "php-${PHP_VERSION}-fileinfo" \
	  "php-${PHP_VERSION}-ftp" \
	  "php-${PHP_VERSION}-iconv" \
	  "php-${PHP_VERSION}-intl" \
	  "php-${PHP_VERSION}-mbstring" \
	  "php-${PHP_VERSION}-opcache" \
	  "php-${PHP_VERSION}-pdo" \
	  "php-${PHP_VERSION}-openssl" \
	  "php-${PHP_VERSION}-mysqlnd" \
	  "php-${PHP_VERSION}-pdo_mysql" \
	  "php-${PHP_VERSION}-pdo_sqlite" \
	  "php-${PHP_VERSION}-phar" \
	  "php-${PHP_VERSION}-posix" \
	  "php-${PHP_VERSION}-simplexml" \
	  "php-${PHP_VERSION}-sodium" \
	  "php-${PHP_VERSION}-xml" \
	  "php-${PHP_VERSION}-xmlreader" \
	  "php-${PHP_VERSION}-xmlwriter"; \
	if [ -f /etc/php/conf.d/10-openssl.ini ]; then mv /etc/php/conf.d/10-openssl.ini /etc/php/conf.d/05-openssl.ini; fi

# Security baseline: non-root runtime user for all variants.
RUN addgroup -S app && adduser -S -G app app
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

FROM base AS runtime-fpm
ARG PHP_VERSION
RUN apk add --no-cache "php-${PHP_VERSION}-fpm"
WORKDIR /app
CMD ["php-fpm", "-F"]

FROM base AS runtime-cli
WORKDIR /app
CMD ["php", "-a"]

FROM base AS runtime-dev
ARG PHP_VERSION
RUN apk add --no-cache "php-${PHP_VERSION}-fpm" gettext "php-${PHP_VERSION}-xdebug"
COPY xdebug.ini /etc/php/conf.d/99-xdebug-settings.ini
WORKDIR /app
CMD ["php-fpm", "-F"]

ARG VARIANT
FROM runtime-${VARIANT} AS final
