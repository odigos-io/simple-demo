#!/usr/bin/env bash
set -euo pipefail

# Stop our service first so it is not running after package removes the unit file
systemctl stop odigos-demo-currency.service 2>/dev/null || true

# Remove pool file from all known locations
find /etc/php -path "*/fpm/pool.d/odigos-demo-currency.conf" -delete 2>/dev/null || true
find /etc/php -path "*/fpm/pool.d/zzz-disable-www.conf"     -delete 2>/dev/null || true
rm -f /etc/php-fpm.d/odigos-demo-currency.conf 2>/dev/null || true

# Reload PHP-FPM units that are still present
for unit in $(systemctl list-units --type=service --all \
             | awk '/php[0-9]+\.[0-9]+-fpm\.service/ {print $1}'); do
  systemctl try-reload-or-restart "$unit" || true
done

# Remove nginx site and reload (only if nginx is installed)
if [ -d /etc/nginx/sites-enabled ]; then
  rm -f /etc/nginx/sites-enabled/odigos-demo-currency.conf 2>/dev/null || true
  rm -f /etc/nginx/sites-available/odigos-demo-currency.conf 2>/dev/null || true
  systemctl reload nginx 2>/dev/null || true
fi


PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
if [ -f "/etc/php/${PHP_VER}/fpm/pool.d/www.conf.disabled" ]; then
  mv "/etc/php/${PHP_VER}/fpm/pool.d/www.conf.disabled" \
     "/etc/php/${PHP_VER}/fpm/pool.d/www.conf"
fi
