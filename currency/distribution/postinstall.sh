# 0) On RHEL/Fedora there is no www-data; use nginx for PHP-FPM pool user
if ! getent passwd www-data >/dev/null 2>&1; then
  for f in /etc/odigos-demo-currency/php-fpm.conf; do
    [ -f "$f" ] && sed -i 's/ = www-data$/ = nginx/g' "$f"
  done
fi

# 1) If nginx is installed, enable our vhost and reload
# Debian/Ubuntu: sites-available + sites-enabled
# RHEL/Fedora: conf.d
if [ -d /etc/nginx/sites-available ]; then
  rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
  install -m0644 /etc/odigos-demo-currency/odigos-demo-currency.nginx.conf \
    /etc/nginx/sites-available/odigos-demo-currency.conf 2>/dev/null || true
  ln -sf /etc/nginx/sites-available/odigos-demo-currency.conf \
         /etc/nginx/sites-enabled/odigos-demo-currency.conf
  systemctl reload nginx 2>/dev/null || true
elif [ -d /etc/nginx/conf.d ]; then
  install -m0644 /etc/odigos-demo-currency/odigos-demo-currency.nginx.conf \
    /etc/nginx/conf.d/odigos-demo-currency.conf 2>/dev/null || true
  systemctl reload nginx 2>/dev/null || true
fi

# 2) install the pool file into the running PHP version only
PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')

install -m0644 -o root -g root \
        /etc/odigos-demo-currency/php-fpm.conf \
        "/etc/php/${PHP_VER}/fpm/pool.d/odigos-demo-currency.conf"

# Disable default www pool (our app pool is odigos-demo-currency)
if [ -f /etc/odigos-demo-currency/disable-www.conf ]; then
  install -m0644 -o root -g root \
          /etc/odigos-demo-currency/disable-www.conf \
          "/etc/php/${PHP_VER}/fpm/pool.d/zzz-disable-www.conf"
elif [ -f "/etc/php/${PHP_VER}/fpm/pool.d/www.conf" ]; then
  mv "/etc/php/${PHP_VER}/fpm/pool.d/www.conf" \
     "/etc/php/${PHP_VER}/fpm/pool.d/www.conf.disabled"
fi

# Disable and stop the distro php-fpm service; our app runs via odigos-demo-currency.service
# Debian/Ubuntu: php8.3-fpm; RHEL/Fedora: php-fpm
systemctl disable "php${PHP_VER}-fpm" 2>/dev/null || true
systemctl stop "php${PHP_VER}-fpm" 2>/dev/null || true
systemctl disable php-fpm 2>/dev/null || true
systemctl stop php-fpm 2>/dev/null || true

# 2.5) On RHEL with SELinux, allow nginx to bind to port 8085 (required even when nginx runs as root)
if [ -d /etc/nginx/conf.d ] && [ -f /sys/fs/selinux/enforce ] && command -v semanage >/dev/null 2>&1; then
  if [ "$(cat /sys/fs/selinux/enforce 2>/dev/null)" = "1" ]; then
    semanage port -l -t http_port_t 2>/dev/null | grep -q ':8085\b' || \
      semanage port -a -t http_port_t -p tcp 8085 2>/dev/null || true
  fi
fi

# 3) Start our service and nginx so the app is reachable after install
systemctl daemon-reload 2>/dev/null || true
systemctl enable odigos-demo-currency.service 2>/dev/null || true
systemctl start odigos-demo-currency.service 2>/dev/null || true
if [ -d /etc/nginx/sites-available ] || [ -d /etc/nginx/conf.d ]; then
  systemctl enable nginx 2>/dev/null || true
  systemctl restart nginx 2>/dev/null || true
fi
