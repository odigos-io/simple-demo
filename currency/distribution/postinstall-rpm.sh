#!/bin/bash
set -e

# 1) Enable nginx configuration (RPM systems use conf.d)
ln -sf /etc/nginx/conf.d/odigos-demo-currency.conf \
       /etc/nginx/conf.d/odigos-demo-currency.conf.enabled

# 2) Restart nginx to pick up the new configuration
if command -v systemctl >/dev/null 2>&1; then
    systemctl restart nginx.service || true
fi

# 3) Enable and start the currency service
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable odigos-demo-currency.service
    systemctl start odigos-demo-currency.service
fi
