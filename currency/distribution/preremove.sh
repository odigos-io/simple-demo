#!/bin/sh
set -e
systemctl disable --now odigos-demo-currency.service || true
rm -f /etc/nginx/sites-enabled/odigos-demo-currency.conf
systemctl reload nginx.service || true
