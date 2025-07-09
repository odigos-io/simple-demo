# 1) make our vhost the default, remove distro’s demo one
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
ln -sf /etc/nginx/sites-available/odigos-demo-currency.conf \
       /etc/nginx/sites-enabled/odigos-demo-currency.conf

# 2) install the pool file into the running PHP version only
PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')

sudo install -m0644 -o root -g root \
        /etc/odigos-demo-currency/php-fpm.conf \
        "/etc/php/${PHP_VER}/fpm/pool.d/odigos-demo-currency.conf"

if [ -f "/etc/php/${PHP_VER}/fpm/pool.d/www.conf" ]; then
  mv "/etc/php/${PHP_VER}/fpm/pool.d/www.conf" \
     "/etc/php/${PHP_VER}/fpm/pool.d/www.conf.disabled"
fi
