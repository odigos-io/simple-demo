#!/usr/bin/env bash
set -euo pipefail

# Stop and disable the currency service
if command -v systemctl >/dev/null 2>&1; then
    systemctl stop odigos-demo-currency.service || true
    systemctl disable odigos-demo-currency.service || true
fi

# Remove nginx configuration & reload
rm -f /etc/nginx/conf.d/odigos-demo-currency.conf.enabled 2>/dev/null || true
systemctl reload nginx || true
