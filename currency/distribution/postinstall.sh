#!/bin/sh
set -e

# Enable nginx vhost
ln -sf /etc/nginx/sites-available/odigos-demo-currency.conf \
       /etc/nginx/sites-enabled/odigos-demo-currency.conf

# Reload services
systemctl daemon-reload
systemctl enable --now php8.3-fpm.service
systemctl reload nginx.service || systemctl restart nginx.service
systemctl enable --now odigos-demo-currency.service
